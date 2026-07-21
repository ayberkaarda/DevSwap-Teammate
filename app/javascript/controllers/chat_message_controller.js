import { Controller } from "@hotwired/stimulus"

// Tek bir sohbet mesajinin satir-ici aksiyonlari: emoji tepkisi, duzenleme, silme.
// Tum degisiklikler sunucuya fetch ile gider; GORSEL guncelleme ActionCable
// yayinlariyla (message_reaction / message_edited / message_deleted) gelir — hem
// aktoru hem odadaki herkesi ayni anda gunceller. Bu yuzden buradan DOM'u elle
// guncellemeyiz (silme haric: yaniti beklerken formu kapatiriz).
export default class extends Controller {
  static values = { id: Number }
  static targets = ["palette", "body", "display", "editForm", "editInput", "editedMarker"]

  togglePicker() {
    if (this.hasPaletteTarget) this.paletteTarget.classList.toggle("hidden")
  }

  react(event) {
    const emoji = event.currentTarget.dataset.emoji
    if (!emoji) return
    this.request("POST", `/messages/${this.idValue}/react`, { emoji })
    if (this.hasPaletteTarget) this.paletteTarget.classList.add("hidden")
  }

  startEdit() {
    if (!this.hasEditFormTarget) return
    this.displayTarget.classList.add("hidden")
    this.editFormTarget.classList.remove("hidden")
    this.editInputTarget.focus()
    const len = this.editInputTarget.value.length
    this.editInputTarget.setSelectionRange(len, len)
  }

  cancelEdit() {
    if (!this.hasEditFormTarget) return
    this.editFormTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }

  submitEdit(event) {
    event.preventDefault()
    const body = this.editInputTarget.value.trim()
    if (!body) return
    this.request("PATCH", `/messages/${this.idValue}`, { message: { body } })
    this.cancelEdit()
  }

  destroy() {
    if (!window.confirm("Bu mesajı silmek istediğine emin misin?")) return
    this.request("DELETE", `/messages/${this.idValue}`)
  }

  request(method, url, body) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    return fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token || "",
        "Accept": "application/json"
      },
      body: body ? JSON.stringify(body) : undefined,
      credentials: "same-origin"
    })
  }
}
