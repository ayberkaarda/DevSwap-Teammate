import { Controller } from "@hotwired/stimulus"

const SKIN_KEY = "terminal-skin"
const SKINS = ["mac", "windows"]

export default class extends Controller {
  connect() {
    this.render(this.currentSkin)
  }

  toggle() {
    const next = SKINS[(SKINS.indexOf(this.currentSkin) + 1) % SKINS.length]
    localStorage.setItem(SKIN_KEY, next)
    this.render(next)
  }

  get currentSkin() {
    const stored = localStorage.getItem(SKIN_KEY)
    return SKINS.includes(stored) ? stored : "mac"
  }

  render(skin) {
    document.documentElement.dataset.terminalSkin = skin
    const labels = { mac: "Windows görünümüne geç", windows: "macOS görünümüne geç" }
    this.element.setAttribute("aria-label", labels[skin])
    this.element.setAttribute("title", labels[skin])
  }
}
