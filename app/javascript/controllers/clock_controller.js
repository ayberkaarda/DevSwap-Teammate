import { Controller } from "@hotwired/stimulus"

// Dashboard "Sistem Saati" widget'ı — client-side, kullanıcının yerel saatini
// gösterir. Her saniye setInterval ile günceller; Turbo navigasyonları arasında
// sızıntı olmaması için disconnect()'te interval mutlaka temizlenir
// (bkz. scroll_to_top_controller.js'deki connect/disconnect temizleme deseni).
export default class extends Controller {
  static targets = ["time", "date"]

  connect() {
    this.render()
    this.timer = setInterval(() => this.render(), 1000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  render() {
    const now = new Date()

    if (this.hasTimeTarget) {
      this.timeTarget.textContent = now.toLocaleTimeString("tr-TR", { hour12: false })
    }

    if (this.hasDateTarget) {
      this.dateTarget.textContent = now.toLocaleDateString("tr-TR", {
        weekday: "long",
        day: "numeric",
        month: "long",
        year: "numeric",
      })
    }
  }
}
