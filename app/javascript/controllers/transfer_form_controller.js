// app/javascript/controllers/transfer_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "articleInput", "articleResults", "articleId",
    "personInput",  "personResults",  "personId"
  ]
  static values = { articlesUrl: String, peopleUrl: String }

  connect() { this.abortCtl = null }

  _fetchJson(url) {
    if (this.abortCtl) this.abortCtl.abort()
    this.abortCtl = new AbortController()
    return fetch(url, { signal: this.abortCtl.signal }).then(r => r.json())
  }
  preventSubmit(e){ e.preventDefault() }

  // ---- Articles
  showArticles() {
    const q = (this.articleInputTarget.value || "").trim()
    const url = `${this.articlesUrlValue}?q=${encodeURIComponent(q)}&per=8`
    this._fetchJson(url).then((resp) => {
      const data = Array.isArray(resp) ? resp : (resp.data || [])
      this.articleResultsTarget.innerHTML = data.map(a => `
        <button type="button" class="ta-item"
          data-id="${a.id}"
          data-label="${a.identificador} — ${a.marca.nombre} ${a.modelo.nombre}"
          data-current="${a.persona_actual ? `${a.persona_actual.nombre} ${a.persona_actual.apellido}` : 'Sin asignar'}">
          ${a.identificador} <span class="muted">— ${a.marca.nombre} ${a.modelo.nombre}</span>
        </button>
      `).join("")
      this.articleResultsTarget.classList.toggle("hidden", data.length === 0)
      this.articleResultsTarget.querySelectorAll(".ta-item").forEach(btn => {
        btn.addEventListener("click", () => this.selectArticle(btn))
      })
    }).catch(() => {})
  }

  selectArticle(btn) {
    this.articleIdTarget.value = btn.dataset.id
    this.articleInputTarget.value = btn.dataset.label
    this.articleResultsTarget.classList.add("hidden")

    // actualizar “Desde (Portador Actual)”
    const fromInput = this.element.querySelector('#from_current_holder')
    if (fromInput) fromInput.value = btn.dataset.current

    // limpiar selección de persona por si quedó algo previo
    if (this.hasPersonIdTarget) this.personIdTarget.value = ""
    if (this.hasPersonInputTarget) this.personInputTarget.value = ""
    if (this.hasPersonResultsTarget) this.personResultsTarget.classList.add("hidden")
  }

  // ---- People
  showPeople() {
    const q = (this.personInputTarget.value || "").trim()
    const url = `${this.peopleUrlValue}?q=${encodeURIComponent(q)}&per=8`
    this._fetchJson(url).then((resp) => {
      const data = Array.isArray(resp) ? resp : (resp.data || [])
      this.personResultsTarget.innerHTML = data.map(p => {
        const label = p.label || `${p.nombre} ${p.apellido}`
        return `<button type="button" class="ta-item" data-id="${p.id}" data-label="${label}">${label}</button>`
      }).join("")
      this.personResultsTarget.classList.toggle("hidden", data.length === 0)
      this.personResultsTarget.querySelectorAll(".ta-item").forEach(btn => {
        btn.addEventListener("click", () => this.selectPerson(btn))
      })
    }).catch(() => {})
  }

  selectPerson(btn) {
    this.personIdTarget.value = btn.dataset.id
    this.personInputTarget.value = btn.dataset.label
    this.personResultsTarget.classList.add("hidden")
  }
}
