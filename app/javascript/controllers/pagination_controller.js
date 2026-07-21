import { Controller } from "@hotwired/stimulus"

// Sayfa içi (client-side) kart sayfalaması. URL değişmez, kartlar
// data-page attribute'una göre gösterilip gizlenir.
export default class extends Controller {
  static targets = ["card", "indicator", "prevButton", "nextButton"]

  connect() {
    this.page = 0
    this.showPage()
  }

  next() {
    if (this.page < this.totalPages - 1) {
      this.page++
      this.showPage()
    }
  }

  prev() {
    if (this.page > 0) {
      this.page--
      this.showPage()
    }
  }

  showPage() {
    this.cardTargets.forEach((card) => {
      const cardPage = parseInt(card.dataset.page, 10)
      card.style.display = cardPage === this.page ? "" : "none"
    })

    if (this.hasIndicatorTarget) {
      this.indicatorTarget.textContent = `Sayfa ${this.page + 1} / ${this.totalPages}`
    }

    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = this.page === 0
    }

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = this.page === this.totalPages - 1
    }
  }

  get totalPages() {
    if (this.cardTargets.length === 0) return 1
    const maxPage = Math.max(...this.cardTargets.map((c) => parseInt(c.dataset.page, 10)))
    return maxPage + 1
  }
}
