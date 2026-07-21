import { Controller } from "@hotwired/stimulus"

// Toast bildirimleri: belirir, kisa sure gorunur kalir, sonra yumusakca
// solup DOM'dan kaldirilir. CSS gecisleriyle "yag gibi" akici his verir.
export default class extends Controller {
  static values = {
    duration: { type: Number, default: 2800 }
  }

  connect() {
    // Giris animasyonu icin baslangic durumu.
    this.element.style.transition = "opacity 0.3s ease, transform 0.3s ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(8px)"

    requestAnimationFrame(() => {
      this.element.style.opacity = "1"
      this.element.style.transform = "translateY(0)"
    })

    this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(8px)"
    setTimeout(() => this.element.remove(), 320)
  }
}
