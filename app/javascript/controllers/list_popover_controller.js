import { Controller } from "@hotwired/stimulus"

// Bir <dialog> acar ve urlValue'daki HTML partial'ini (begenenler / repost edenler
// listesi) fetch ile icine yukler. Begeni/repost sayisina tiklaninca kullanilir.
export default class extends Controller {
  static targets = ["dialog", "content"]
  static values = { url: String }

  async open() {
    this.contentTarget.innerHTML =
      "<p class='text-text-muted text-xs font-mono p-4'>Yükleniyor...</p>"
    if (typeof this.dialogTarget.showModal === "function") this.dialogTarget.showModal()

    try {
      const res = await fetch(this.urlValue, { headers: { Accept: "text/html" } })
      this.contentTarget.innerHTML = await res.text()
    } catch (e) {
      this.contentTarget.innerHTML =
        "<p class='text-status-err text-xs font-mono p-4'>Liste yüklenemedi.</p>"
    }
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
