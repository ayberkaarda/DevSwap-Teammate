import { Controller } from "@hotwired/stimulus"

const THEME_KEY = "theme"
const MODES = ["system", "light", "dark", "dracula", "monokai", "nord", "solarized", "gruvbox", "onedark", "tokyonight", "matrix"]
const DARK_MODES = ["dark", "dracula", "monokai", "nord", "solarized", "gruvbox", "onedark", "tokyonight", "matrix"]

const LABELS = {
  system: "Sistem",
  light: "Açık",
  dark: "Koyu",
  dracula: "Dracula",
  monokai: "Monokai",
  nord: "Nord",
  solarized: "Solarized",
  gruvbox: "Gruvbox",
  onedark: "One Dark",
  tokyonight: "Tokyo Night",
  matrix: "Matrix",
}

const ICONS = {
  system: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>',
  light: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/></svg>',
  dark: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79Z"/></svg>',
  dracula: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2C8 6 6 10 6 13a6 6 0 0 0 12 0c0-3-2-7-6-11Z"/></svg>',
  monokai: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/></svg>',
  nord: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 17l5-5-5-5M12 19h10"/><path d="M6 6l-4 6 4 6"/></svg>',
  solarized: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 16a4 4 0 0 0 0-8"/><path d="M2 16h20"/></svg>',
  gruvbox: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="12" cy="12" r="1.5"/></svg>',
  onedark: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="1.5" fill="currentColor"/><ellipse cx="12" cy="12" rx="9" ry="4"/><ellipse cx="12" cy="12" rx="4" ry="9"/></svg>',
  tokyonight: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5Z"/></svg>',
  matrix: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6l5 6-5 6"/><path d="M13 18h7"/></svg>',
}

// Connects to data-controller="theme"
export default class extends Controller {
  static targets = ["icon", "label", "menu", "option"]

  connect() {
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.onMediaChange = this.onMediaChange.bind(this)
    this.media.addEventListener("change", this.onMediaChange)

    this.render(this.currentMode)
  }

  disconnect() {
    this.media.removeEventListener("change", this.onMediaChange)
  }

  select(event) {
    const nextMode = event.params.mode
    if (!MODES.includes(nextMode)) return

    localStorage.setItem(THEME_KEY, nextMode)
    this.render(nextMode)

    if (this.hasMenuTarget) this.menuTarget.open = false
  }

  onMediaChange() {
    if (this.currentMode === "system") {
      this.applyResolvedTheme("system")
    }
  }

  get currentMode() {
    const stored = localStorage.getItem(THEME_KEY)
    return MODES.includes(stored) ? stored : "system"
  }

  resolveTheme(mode) {
    if (mode === "system") return this.media.matches ? "dark" : "light"
    return mode
  }

  applyResolvedTheme(mode) {
    const resolved = this.resolveTheme(mode)
    const root = document.documentElement

    root.dataset.theme = resolved
    root.classList.toggle("dark", DARK_MODES.includes(resolved))
  }

  render(mode) {
    this.applyResolvedTheme(mode)
    this.updateIcon(mode)
    this.updateOptions(mode)
    this.updateAriaLabel(mode)
  }

  updateIcon(mode) {
    if (this.hasIconTarget) this.iconTarget.innerHTML = ICONS[mode] || ICONS.system
    if (this.hasLabelTarget) this.labelTarget.textContent = LABELS[mode] || LABELS.system
  }

  updateOptions(mode) {
    this.optionTargets.forEach((option) => {
      const isActive = option.dataset.themeMode === mode
      option.setAttribute("aria-current", isActive ? "true" : "false")
      option.classList.toggle("text-accent", isActive)
      option.classList.toggle("text-text-muted", !isActive)
    })
  }

  updateAriaLabel(mode) {
    const label = `Tema: ${LABELS[mode] || LABELS.system}`
    this.element.setAttribute("aria-label", label)
    this.element.setAttribute("title", label)
  }
}
