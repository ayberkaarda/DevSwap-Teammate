import { Controller } from "@hotwired/stimulus"

// /rooms/:slug sag kenar cubugundaki DM kisi arama kutusu (client-side).
// input'a yazildikca, data-name'i sorgu metnini (substring, case-insensitive)
// icermeyen kisi satirlarini gizler. Hicbir sey sunucuya gitmez.
export default class extends Controller {
  static targets = ["input", "item", "empty"]

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let visibleCount = 0

    this.itemTargets.forEach((item) => {
      const name = (item.dataset.name || "").toLowerCase()
      const match = name.includes(query)
      item.classList.toggle("hidden", !match)
      if (match) visibleCount += 1
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visibleCount > 0)
    }
  }
}
