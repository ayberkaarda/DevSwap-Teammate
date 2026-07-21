import { Controller } from "@hotwired/stimulus"

// "Gonder" (postu DM olarak paylas) modali: kisi listesini dialog acilirken
// BIR KEZ fetch ile yukler (yalnizca current_user'in mevcut DM partnerleri —
// bkz. PostSharesController#share_targets). Searchbox sunucuya tekrar
// gitmez; yalnizca zaten yuklenmis satirlar arasinda CLIENT-SIDE substring
// filtrelemesi yapar (bkz. filter()). Boylece daha once hic DM'lesilmemis
// bir kullaniciya post paylasimi UZERINDEN ulasilamaz — yeni sohbet baslatmak
// icin profil sayfasindaki normal "mesaj gonder" akisi kullanilmalidir.
export default class extends Controller {
  static targets = ["dialog", "content", "search"]
  static values = { url: String }

  async open() {
    if (this.hasSearchTarget) this.searchTarget.value = ""
    if (typeof this.dialogTarget.showModal === "function") this.dialogTarget.showModal()
    await this.load()
  }

  // Arama kutusu: yalnizca zaten yuklenmis (DM partnerleri) satirlar
  // arasinda client-side filtreler. Sunucuya YENIDEN istek atmaz.
  filter() {
    const q = this.searchTarget.value.trim().toLowerCase()
    const rows = this.contentTarget.querySelectorAll("[data-share-name]")
    rows.forEach((row) => {
      const name = (row.dataset.shareName || "").toLowerCase()
      row.hidden = q.length > 0 && !name.includes(q)
    })
  }

  async load() {
    this.contentTarget.innerHTML =
      "<p class='text-text-muted text-xs font-mono p-4'>Yükleniyor...</p>"

    try {
      const res = await fetch(this.urlValue, { headers: { Accept: "text/html" } })
      const html = await res.text()
      this.contentTarget.innerHTML = html
    } catch (e) {
      this.contentTarget.innerHTML =
        "<p class='text-status-err text-xs font-mono p-4'>Kişi listesi yüklenemedi.</p>"
    }
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  // Bir kisi satirindaki "Gonder" formu tamamlaninca dialog'u kapat. Sunucu
  // ayrica turbo_stream ile etkilesim cubugunu (ve dialog'u) tazeler; bu yalnizca
  // ek bir guvence ( or. self-share hata yolunda replace olmadiginda kapatir).
  submitEnd(event) {
    if (event.detail && event.detail.success) this.close()
  }
}
