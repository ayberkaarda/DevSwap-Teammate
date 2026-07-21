import { Controller } from "@hotwired/stimulus"

// Client-side hava durumu widget'ı. Rails backend'i yok:
// tarayıcı geolocation izni + Open-Meteo (API key gerektirmez) kullanır.
export default class extends Controller {
  static targets = ["temp", "description", "wind", "status"]

  // WMO weather_code -> { emoji, text } (yaygın aralıkları kapsayan küçük tablo)
  static CODE_MAP = {
    0: { emoji: "☀️", text: "Açık" },
    1: { emoji: "🌤️", text: "Parçalı bulutlu" },
    2: { emoji: "⛅", text: "Parçalı bulutlu" },
    3: { emoji: "☁️", text: "Bulutlu" },
    45: { emoji: "🌫️", text: "Sisli" },
    48: { emoji: "🌫️", text: "Sisli" },
    51: { emoji: "🌦️", text: "Çisenti" },
    61: { emoji: "🌧️", text: "Yağmurlu" },
    71: { emoji: "🌨️", text: "Karlı" },
    80: { emoji: "🌧️", text: "Sağanak" },
    95: { emoji: "⛈️", text: "Fırtına" }
  }

  // Stimulus connect() her Turbo navigasyonunda (turbo:load ile controller
  // yeniden bağlanır) tetiklenir; bu yüzden dashboard'a her girişte tarayıcı
  // yenilemeye gerek kalmadan hava durumu YENİDEN çekilir. Ayrıca widget açık
  // kalırsa 15 dakikada bir tazelenir.
  connect() {
    if (!("geolocation" in navigator)) {
      this.showError("Konum desteklenmiyor")
      return
    }

    this.locateAndFetch()

    // Periyodik tazeleme (15 dk) — widget uzun süre açık kalırsa güncel kalsın.
    this.refreshTimer = setInterval(() => this.locateAndFetch(), 15 * 60 * 1000)
  }

  disconnect() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
      this.refreshTimer = null
    }
  }

  // Konumu al ve hava durumunu çek. maximumAge ile son 10 dk içindeki önbelleğe
  // alınmış konum kabul edilir; bu, Turbo navigasyonlarında tekrar tekrar izin
  // istemeden hızlı yeniden-çekmeyi sağlar.
  locateAndFetch() {
    if (!("geolocation" in navigator)) return

    navigator.geolocation.getCurrentPosition(
      (pos) => this.fetchWeather(pos.coords.latitude, pos.coords.longitude),
      () => this.showError("Konum izni verilmedi"),
      { timeout: 10000, maximumAge: 10 * 60 * 1000 }
    )
  }

  fetchWeather(lat, lon) {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto`

    fetch(url)
      .then((res) => {
        if (!res.ok) throw new Error("HTTP " + res.status)
        return res.json()
      })
      .then((data) => this.render(data))
      .catch(() => this.showError("Hava durumu alınamadı"))
  }

  render(data) {
    const current = data && data.current
    if (!current) {
      this.showError("Hava durumu alınamadı")
      return
    }

    const code = current.weather_code
    const info = this.constructor.CODE_MAP[code] || this.mapRange(code)

    if (this.hasTempTarget) {
      this.tempTarget.textContent = `${Math.round(current.temperature_2m)}°C`
    }
    if (this.hasDescriptionTarget) {
      this.descriptionTarget.textContent = `${info.emoji} ${info.text}`
    }
    if (this.hasWindTarget) {
      this.windTarget.textContent = `${Math.round(current.wind_speed_10m)} km/s rüzgâr`
    }
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = ""
      this.statusTarget.classList.add("hidden")
    }
  }

  // CODE_MAP'te olmayan kodlar için aralık bazlı geri dönüş.
  mapRange(code) {
    if (code >= 1 && code <= 3) return { emoji: "⛅", text: "Parçalı bulutlu" }
    if (code === 45 || code === 48) return { emoji: "🌫️", text: "Sisli" }
    if (code >= 51 && code <= 67) return { emoji: "🌧️", text: "Yağmurlu" }
    if (code >= 71 && code <= 77) return { emoji: "🌨️", text: "Karlı" }
    if (code >= 80 && code <= 99) return { emoji: "⛈️", text: "Fırtına" }
    return { emoji: "🌡️", text: "Bilinmiyor" }
  }

  showError(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.classList.remove("hidden")
    }
    if (this.hasTempTarget) this.tempTarget.textContent = "--"
    if (this.hasDescriptionTarget) this.descriptionTarget.textContent = ""
    if (this.hasWindTarget) this.windTarget.textContent = ""
  }
}
