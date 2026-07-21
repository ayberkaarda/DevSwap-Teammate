import { Controller } from "@hotwired/stimulus"

// Skill duzenleme mini-formlari icin otomatik kaydetme. Bir alan
// blur/change olayi aldiginda formu otomatik submit eder, boylece
// kullanici baska bir skill'in "duzenle" akordeonunu acip (native
// <details name="..."> davranisiyla) bu formu kapattiginda veri
// zaten kaydedilmis olur.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
