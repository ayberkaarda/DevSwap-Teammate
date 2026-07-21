import { Controller } from "@hotwired/stimulus"

// Yukari cik butonu. Sayfa 300px'den fazla kaydirildiginda buton yumusakca
// belirir (.is-visible), tiklaninca smooth scroll ile en uste doner.
export default class extends Controller {
  connect() {
    this.threshold = 300
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    this.element.classList.toggle("is-visible", window.scrollY > this.threshold)
  }

  top() {
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
