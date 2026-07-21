import { Controller } from "@hotwired/stimulus"
import { GridStack } from "gridstack"

// Profil ızgara kontrolcüsü.
// dashboard_grid_controller ile ANALOG ama AYRI: PATCH'ler /profile_widgets/*
// uçlarına gider. Kritik fark: bu controller yalnızca profil SAHİBİ kendi
// profiline bakarken (edit yeteneğiyle) markup'a eklenir. Başka bir ziyaretçi
// (giriş yapmamış dahil) için data-controller HİÇ eklenmez, dolayısıyla ızgara
// asla sürüklenebilir/boyutlandırılabilir olmaz — tamamen salt-okunur render.
export default class extends Controller {
  static targets = ["grid", "editButton", "hiddenList"]

  connect() {
    // Gridstack yüklenemediyse sessizce çık (sayfa yine de çalışsın).
    if (typeof GridStack === "undefined" || !GridStack) {
      console.warn("[profile-grid] GridStack yüklenemedi")
      return
    }
    if (!this.hasGridTarget) return

    this.editing = false

    // İzgarayı kilitli (salt-okunur) başlat.
    this.grid = GridStack.init(
      {
        column: 12,
        float: true,
        disableDrag: true,
        disableResize: true,
        margin: 8,
        cellHeight: 70
      },
      this.gridTarget
    )

    // Layout değiştiğinde (taşıma/boyutlandırma bittiğinde) sunucuya yaz.
    // Controller artık SAHİP OLMAYAN ziyaretçilerde de bağlanır (Gridstack'in
    // widget'ları konumlandırması için — aksi halde hepsi üst üste yığılır).
    // Ancak yalnızca SAHİP (edit araç çubuğu = editButton hedefi olan) layout
    // PATCH'i gönderebilmeli; salt-okunur ziyaretçide init sırasında oluşabilecek
    // "change" olayının sunucuya (reddedilecek) istek atmasını engelle.
    if (this.hasEditButtonTarget) {
      this.grid.on("change", (event, items) => this.persistLayout(items))
    }
  }

  disconnect() {
    if (this.grid) {
      try {
        this.grid.off("change")
        this.grid.destroy(false) // DOM elemanlarını koru, sadece izgarayı bırak
      } catch (_e) {
        // yut
      }
      this.grid = null
    }
  }

  // "Düzenle" <-> "Bitir" geçişi
  toggleEdit() {
    if (!this.grid) return
    this.editing = !this.editing

    if (this.editing) {
      // Edit moduna gir: taşıma/boyutlandırma aç, chrome'u göster.
      this.grid.enableMove(true)
      this.grid.enableResize(true)
      this.gridTarget.classList.add("edit-mode")
      this.element.classList.add("edit-mode")
      if (this.hasHiddenListTarget) {
        this.hiddenListTarget.classList.add("edit-mode")
        this.hiddenListTarget.classList.remove("hidden")
      }
      if (this.hasEditButtonTarget) this.editButtonTarget.textContent = "Bitir"
    } else {
      // Edit modundan çık: mevcut layout'u kaydet, kilitle, chrome'u gizle.
      try {
        this.persistLayout(this.grid.save(false))
      } catch (_e) {
        // save başarısız olursa yut; change eventi zaten yazmış olabilir.
      }
      this.grid.enableMove(false)
      this.grid.enableResize(false)
      this.gridTarget.classList.remove("edit-mode")
      this.element.classList.remove("edit-mode")
      if (this.hasHiddenListTarget) {
        this.hiddenListTarget.classList.remove("edit-mode")
        this.hiddenListTarget.classList.add("hidden")
      }
      if (this.hasEditButtonTarget) this.editButtonTarget.textContent = "Düzenle"
    }
  }

  // Değişen widget'ların id + geometrisini toplayıp reorder'a PATCH eder.
  persistLayout(items) {
    if (!items || !items.length) return

    const widgets = []
    items.forEach((node) => {
      const id = this.nodeId(node)
      if (!id) return
      widgets.push({
        id: Number(id),
        position_x: node.x,
        position_y: node.y,
        width: node.w,
        height: node.h
      })
    })
    if (!widgets.length) return

    this.patchJson("/profile_widgets/reorder", { widgets })
  }

  // Bir gridstack node'undan DB id'sini (gs-id) okur.
  nodeId(node) {
    if (node && node.id != null && node.id !== "") return node.id
    const el = node && node.el ? node.el : null
    if (el && el.getAttribute) return el.getAttribute("gs-id")
    return null
  }

  // "Gizle": widget'ı görünmez yap ve izgaradan çıkar.
  hideWidget(event) {
    const itemEl = event.target.closest(".grid-stack-item")
    if (!itemEl) return
    const id = itemEl.getAttribute("gs-id")
    if (!id) return

    this.patchJson(`/profile_widgets/${id}`, {
      profile_widget: { visible: false }
    }).then((ok) => {
      if (ok && this.grid) {
        this.grid.removeWidget(itemEl)
      }
    })
  }

  // Gizli widget'ı tekrar görünür yap. Grid'e temiz şekilde geri eklenmesi için
  // sayfa yeniden yüklenir (dashboard'daki non-chatbox davranışıyla aynı).
  showWidget(event) {
    const btn = event.currentTarget
    const id = btn.dataset.widgetId
    if (!id) return

    this.patchJson(`/profile_widgets/${id}`, {
      profile_widget: { visible: true }
    }).then((ok) => {
      if (ok) window.location.reload()
    })
  }

  // Yazıyı büyüt (+0.1)
  fontUp(event) {
    this.adjustFont(event, 0.1)
  }

  // Yazıyı küçült (-0.1)
  fontDown(event) {
    this.adjustFont(event, -0.1)
  }

  // Yazı ölçeğini 0.5–2.0 arası, 0.1 adımlarla değiştirir; CSS custom
  // property'yi günceller ve sunucuya PATCH eder.
  adjustFont(event, delta) {
    const itemEl = event.target.closest(".grid-stack-item")
    if (!itemEl) return
    const id = itemEl.getAttribute("gs-id")
    const content = itemEl.querySelector(".grid-stack-item-content")
    if (!content) return

    const current = parseFloat(content.style.getPropertyValue("--widget-font-scale")) || 1.0
    let next = Math.round((current + delta) * 10) / 10
    next = Math.min(2.0, Math.max(0.5, next))
    if (next === current) return

    content.style.setProperty("--widget-font-scale", String(next))

    if (id) {
      this.patchJson(`/profile_widgets/${id}`, {
        profile_widget: { font_scale: next }
      })
    }
  }

  // CSRF token'ı meta etiketinden okur (yoksa boş string).
  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }

  // Ortak JSON PATCH yardımcı fonksiyonu. Başarı durumunda true döner.
  async patchJson(url, body) {
    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify(body)
      })
      if (!response.ok) {
        console.warn(`[profile-grid] PATCH ${url} başarısız: ${response.status}`)
        return false
      }
      return true
    } catch (error) {
      console.warn(`[profile-grid] PATCH ${url} ağ hatası`, error)
      return false
    }
  }
}
