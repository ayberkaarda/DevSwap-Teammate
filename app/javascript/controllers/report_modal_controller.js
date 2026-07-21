import { Controller } from "@hotwired/stimulus"

// Global sikayet modali. _floating_post_button_controller ile ayni etkilesim
// deseni: native <dialog>, Esc/backdrop/kapat tusu ile kapanir, basarili
// gonderimde panel kapanir.
//
// Tetikleme heterojendir (profil butonu ID bilir, sohbet /report komutu sadece
// yazilmis bir isim bilir), bu yuzden her iki kaynak da ayni global custom
// event'i tetikler:
//   document.dispatchEvent(new CustomEvent("report:open", { detail: { username } }))
// connect() bu event'i dinler, hedef ismi gizli alana + salt-okunur gosterime
// yazar ve modali acar.
export default class extends Controller {
  static targets = ["dialog", "username", "targetDisplay"]

  connect() {
    // Yalnizca gercek modal ornegi (dialog tasiyan) global event'i dinler.
    // Profil butonu gibi dialog'suz ornekler yalnizca event tetikler (openFromButton).
    if (!this.hasDialogTarget) return

    this.onReportOpen = (event) => {
      const username = (event.detail && event.detail.username) || ""
      if (this.hasUsernameTarget) this.usernameTarget.value = username
      if (this.hasTargetDisplayTarget) this.targetDisplayTarget.value = username
      this.open()
    }
    document.addEventListener("report:open", this.onReportOpen)
  }

  disconnect() {
    if (this.onReportOpen) document.removeEventListener("report:open", this.onReportOpen)
  }

  // Profil sayfasindaki "Şikayet Et" butonu icin: hedef ismi param'dan alip
  // ayni global event'i tetikler; katmandaki modal ornegi bunu yakalayip acar.
  openFromButton(event) {
    const username = event.params && event.params.username
    document.dispatchEvent(new CustomEvent("report:open", { detail: { username } }))
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

  // <dialog> tiklamalari: hedef bizzat dialog ise (::backdrop'a tiklandi) kapat.
  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  submitEnd(event) {
    if (event.detail && event.detail.success) this.close()
  }
}
