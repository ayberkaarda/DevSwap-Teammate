import { Controller } from "@hotwired/stimulus"

// Yuzen "Post Oluştur" butonu. Butona tiklaninca native <dialog> modal acilir;
// Esc'e basinca (dialog varsayilani) veya arka plana / kapat tusuna tiklaninca
// kapanir. Form basariyla gonderildiginde panel kapanir (geri bildirim toast'i
// sunucudan flash olarak gelir).
export default class extends Controller {
  static targets = ["dialog", "content", "charCount"]

  // İçerik textarea'sının canlı karakter sayacı (ör. "42/500"). Salt kozmetik;
  // acilma/kapanma/backdrop/submit davranisini etkilemez.
  updateCharCount() {
    if (!this.hasContentTarget || !this.hasCharCountTarget) return
    const max = this.contentTarget.maxLength > 0 ? this.contentTarget.maxLength : 500
    this.charCountTarget.textContent = `${this.contentTarget.value.length}/${max}`
  }

  open() {
    if (this.hasDialogTarget && typeof this.dialogTarget.showModal === "function") {
      this.dialogTarget.showModal()
    }
  }

  close() {
    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close()
    }
  }

  // <dialog> tiklamalari: hedef bizzat dialog ise (yani ::backdrop'a tiklandi) kapat.
  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  submitEnd(event) {
    if (event.detail && event.detail.success) this.close()
  }
}
