import { Controller } from "@hotwired/stimulus"

// Dashboard "Terminal Kısayolları" widget'ı — bir komuta tıklanınca terminal
// chat kutusunu (bkz. app/views/dashboard/_chat_panel.html.erb, id="message_body")
// o komut metniyle doldurur ve odaklar. Chatbox widget'ı gizliyse/mevcut değilse
// sessizce hiçbir şey yapmaz (hata fırlatmaz).
export default class extends Controller {
  fill(event) {
    const command = event.currentTarget.dataset.command
    if (!command) return

    const input = document.getElementById("message_body")
    if (!input) return

    input.value = command
    input.focus()
  }
}
