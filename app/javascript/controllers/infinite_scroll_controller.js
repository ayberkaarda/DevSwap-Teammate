import { Controller } from "@hotwired/stimulus"

// Sonsuz kaydirma (infinite scroll). Listenin altindaki "sentinel" elemani
// gorunur alana yaklastiginda (IntersectionObserver, 300px onceden) bir
// sonraki sayfayi turbo_stream olarak ceker ve mevcut listeye ekler.
// Sayfa yenilenmez. Sentinel turbo_stream ile degistiginden yeni sentinel'i
// otomatik olarak (targetConnected) tekrar gozlemler.
//
// ONEMLI (Turbo Drive + Stimulus yasam dongusu): Turbo Drive'in snapshot
// onbellegi (preview) ile bir filtre gezinmesi (arama/siralama/aralik) sonrasi
// Stimulus, `sentinelTargetConnected`/`Disconnected` geri cagrilarini `connect()`
// CALISMADAN tetikleyebilir. Observer'i yalnizca connect()'te kursaydik bu
// durumda `this.observer` undefined olur ve `.observe()/.unobserve()` bir
// TypeError firlatirdi; bu YAKALANMAYAN hata, Stimulus'un o mutasyon
// yigininindaki KALAN controller'lari (ustteki compose formunun tag-picker'i
// dahil) baglamasini yarida keser — yani filtreledikten sonra compose formu
// islevsizlesir. Bu yuzden observer'i tembel (lazy) kuruyor ve tum geri
// cagrilari observer yoklugu ihtimaline karsi koruyoruz.
export default class extends Controller {
  static targets = ["sentinel"]

  connect() {
    this.loading = false
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
      this.observer = null
    }
  }

  // Observer'i, connect() calismis olsun ya da olmasin, ilk ihtiyac aninda kur.
  ensureObserver() {
    if (!this.observer) {
      this.observer = new IntersectionObserver(
        (entries) => this.handleIntersect(entries),
        { rootMargin: "300px 0px" }
      )
    }
    return this.observer
  }

  sentinelTargetConnected(element) {
    this.ensureObserver().observe(element)
  }

  sentinelTargetDisconnected(element) {
    if (this.observer) this.observer.unobserve(element)
  }

  handleIntersect(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) this.loadMore(entry.target)
    })
  }

  async loadMore(sentinel) {
    const url = sentinel.dataset.nextUrl
    if (!url || this.loading) return

    this.loading = true
    try {
      const response = await fetch(url, {
        headers: { Accept: "text/vnd.turbo-stream.html" }
      })
      if (response.ok && window.Turbo) {
        const html = await response.text()
        window.Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      // Ag hatasi: sessizce yut, bir sonraki kaydirmada tekrar denenir.
    } finally {
      this.loading = false
    }
  }
}
