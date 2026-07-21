import { Controller } from "@hotwired/stimulus"

// Minimal DM Modu (Faz 31e) için ince UI toggle kontrolcüsü.
// open(): tıklanan DM kutusunun/avatarının data-room-url'ini chat_panel Turbo
// Frame'inin src'ine yazar (frame promotion sayesinde rooms#show yanıtından
// eşleşen frame içeriği çekilir) ve yukarı açılan popup'ı gösterir. Asıl chat
// işlevselliği (canlı güncelleme) yüklenen içerik + mevcut ActionCable JS ile
// otomatik gelir.
export default class extends Controller {
  static targets = ["popup", "frame"]

  open(event) {
    const url = event.currentTarget.dataset.roomUrl
    if (url && this.hasFrameTarget) {
      this.frameTarget.setAttribute("src", url)
    }
    if (this.hasPopupTarget) {
      this.popupTarget.classList.remove("hidden")
    }
  }

  close() {
    if (this.hasPopupTarget) {
      this.popupTarget.classList.add("hidden")
    }
  }
}
