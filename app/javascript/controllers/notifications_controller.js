import { Controller } from "@hotwired/stimulus"

// Zil (bildirim) menusu. <details> acildiginda aktif bildirimleri sunucuda
// "gorulmus" isaretler ve "+N" rozetini gizler; boylece kullanici bildirimleri
// GORDUKTEN sonra sayac kaybolur, geriye sade zil ikonu kalir.
export default class extends Controller {
  static targets = ["badge"]
  static values = { markSeenUrl: String }

  // data-action="toggle->notifications#markSeen" ile <details> toggle olayina bagli.
  markSeen(event) {
    // Yalnizca ACILDIGINDA isaretle (kapanista degil).
    if (event?.target && event.target.open === false) return
    if (this.seen) return
    this.seen = true

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.markSeenUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token || "",
        "Accept": "application/json"
      },
      credentials: "same-origin"
    }).catch(() => {})

    this.badgeTargets.forEach((el) => el.remove())
  }
}
