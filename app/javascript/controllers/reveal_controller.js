import { Controller } from "@hotwired/stimulus"

// Gizli oge listesini parca parca acar (varsayilan +5). Yorum yanitlarinin
// "devamini goster" davranisini saglar: kapali gelir, ilk N gorunur, her
// tiklamada +step kadar daha acilir.
export default class extends Controller {
  static targets = ["item", "button"]
  static values = { step: { type: Number, default: 5 } }

  connect() {
    this.shown = this.stepValue
    this.update()
  }

  more() {
    this.shown += this.stepValue
    this.update()
  }

  update() {
    this.itemTargets.forEach((el, i) => {
      el.hidden = i >= this.shown
    })
    if (this.hasButtonTarget) {
      this.buttonTarget.hidden = this.shown >= this.itemTargets.length
    }
  }
}
