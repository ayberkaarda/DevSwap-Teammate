import { Controller } from "@hotwired/stimulus"

// Post olusturma etiket secici. profiles/edit.html.erb'deki <datalist> tabanli
// serbest-metin autocomplete desenini yeniden kullanir: kullanici bir yetenek
// adi yazip (ya da listeden secip) Enter'a basar; secilen yetenek kaldirilabilir
// bir "chip" olarak render edilir ve altina gizli bir <input name="skill_ids[]">
// eklenir. Boylece PostsController#create'in bekledigi skill_ids[] param dizisi
// hic degismeden gonderilir — cirkin checkbox izgarasi tamamen kalkar.
//
// Yalnizca datalist'te GERCEKTEN var olan yetenekler eklenebilir; her <option>
// data-skill-id tasidigindan chip'in gizli input degeri skill.id olur (isim degil).
export default class extends Controller {
  static targets = ["input", "chips"]

  connect() {
    // Ayni yetenegin iki kez eklenmesini engellemek icin secili id kumesi.
    this.selectedIds = new Set()
  }

  // change  -> datalist'ten secim yapilinca veya input blur olunca
  // keydown -> tam isim yazip Enter'a basinca (Enter formu submit etmesin)
  add(event) {
    if (event.type === "keydown") {
      if (event.key !== "Enter") return
      event.preventDefault()
    }

    this.commitValue(this.inputTarget.value)
  }

  // submit -> form gonderilmeden once yazilmis ama Enter'a basilmamis
  // (henuz chip'e donusmemis) degeri isle. Enter/change tetiklenmeden
  // "Yayınla"ya basilirsa yazilan etiketin kaybolmasini engeller.
  commitPending() {
    this.commitValue(this.inputTarget.value)
  }

  // Ortak cekirdek: trim -> datalist option bul -> id ile tekillestir -> chip ekle.
  // add() ve commitPending() ikisi de burayi cagirir; bilinmeyen serbest metin
  // asla eklenmez (yalnizca gercek datalist yetenekleri).
  commitValue(rawValue) {
    const value = (rawValue || "").trim()
    if (value === "") return

    const option = this.findOption(value)
    if (!option) return // bilinmeyen serbest metin eklenmez

    const id = option.dataset.skillId
    const name = option.value
    this.inputTarget.value = ""

    if (!id || this.selectedIds.has(id)) return

    this.selectedIds.add(id)
    this.renderChip(id, name)
  }

  // Yazilan degere (buyuk/kucuk harf duyarsiz) tam eslesen datalist option'i bul.
  findOption(value) {
    const lower = value.toLowerCase()
    return Array.from(this.element.querySelectorAll("datalist option"))
      .find((o) => o.value.toLowerCase() === lower)
  }

  renderChip(id, name) {
    const chip = document.createElement("span")
    chip.dataset.skillId = id
    chip.className =
      "inline-flex items-center gap-1 text-[11px] font-mono bg-accent/10 " +
      "text-accent border border-accent/30 px-2 py-0.5 rounded-sm"

    const label = document.createElement("span")
    label.textContent = name

    const remove = document.createElement("button")
    remove.type = "button"
    remove.textContent = "×"
    remove.className = "font-bold leading-none hover:opacity-70 cursor-pointer"
    remove.setAttribute("aria-label", `${name} etiketini kaldır`)
    remove.dataset.action = "tag-picker#remove"

    const hidden = document.createElement("input")
    hidden.type = "hidden"
    hidden.name = "skill_ids[]"
    hidden.value = id

    chip.append(label, remove, hidden)
    this.chipsTarget.appendChild(chip)
  }

  remove(event) {
    const chip = event.target.closest("[data-skill-id]")
    if (!chip) return
    this.selectedIds.delete(chip.dataset.skillId)
    chip.remove()
  }
}
