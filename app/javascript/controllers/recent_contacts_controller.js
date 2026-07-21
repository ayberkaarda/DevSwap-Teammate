import { Controller } from "@hotwired/stimulus"

// Son etkileşimler widget'ı için sayfa-içi (client-side) sayfalama.
// 4'erli DOM gruplarını data-page attribute'una göre gösterir/gizler.
export default class extends Controller {
  static targets = ["page", "indicator", "prevButton", "nextButton"]

  connect() {
    this.index = 0
    this.showPage()
  }

  next() {
    if (this.index < this.pageTargets.length - 1) {
      this.index++
      this.showPage()
    }
  }

  prev() {
    if (this.index > 0) {
      this.index--
      this.showPage()
    }
  }

  showPage() {
    this.pageTargets.forEach((el, i) => {
      el.classList.toggle("hidden", i !== this.index)
    })

    if (this.hasIndicatorTarget) {
      this.indicatorTarget.textContent = `${this.index + 1} / ${this.pageTargets.length}`
    }
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = this.index === 0
    }
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = this.index >= this.pageTargets.length - 1
    }
  }
}
