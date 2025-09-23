import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["brandsSection", "modelsSection"]

  // Tabs
  showBrands() {
    this.brandsSectionTarget.style.display = ""
    this.modelsSectionTarget.style.display = "none"
    this._moveKnob("left"); this._setAddButton("brand")
  }
  showModels() {
    this.brandsSectionTarget.style.display = "none"
    this.modelsSectionTarget.style.display = ""
    this._moveKnob("right"); this._setAddButton("model")
  }
  _moveKnob(where){
    const knob = document.querySelector(".tab-knob")
    const links = document.querySelectorAll(".tab-link")
    if (where === "right") knob?.classList.add("to-right"); else knob?.classList.remove("to-right")
    links[0]?.classList.toggle("is-active", where !== "right")
    links[1]?.classList.toggle("is-active", where === "right")
  }
  _setAddButton(type){
    const btn = document.querySelector('[data-action="catalog#openNew"]')
    if (!btn) return
    btn.dataset.catalogTypeParam = type
    btn.textContent = `+ Agregar ${type === "brand" ? "Marca" : "Modelo"}`
  }

  // Abrir modales
  openNew(e) {
    const type = e.params.type // 'brand' | 'model'
    const modal = document.querySelector('[data-controller="catalog-modal"]')
    type === "brand" ? modal.__openBrand({}) : modal.__openModel({})
  }

  openEdit(e) {
    const type = e.params.type
    const modal = document.querySelector('[data-controller="catalog-modal"]')

    if (type === "brand") {
      const name = e.params.name ?? e.params.nombre ?? ""
      modal.__openBrand({ id: e.params.id, name })
    } else {
      const name    = e.params.name    ?? e.params.nombre ?? ""
      const year    = e.params.year    ?? ""
      const brandId = e.params.brandId ?? e.params.brand_id ?? ""
      modal.__openModel({ id: e.params.id, name, year, brandId })
    }
  }

  // Eliminar con guard y mensajes correctos
  async confirmDelete(e) {
    const { type, id } = e.params
    if (type === "brand") {
      const modelos = Number(e.params.modelsCount || 0)
      if ( modelos > 0 ) { alert("No se puede eliminar: tiene modelos asociados"); return }
    } else {
      const arts = Number(e.params.articlesCount || 0)
      if ( arts > 0 ) { alert("No se puede eliminar: tiene artículos asociados"); return }
    }
    if (!confirm("¿Eliminar definitivamente?")) return

    const res = await fetch(`/${type === 'brand' ? 'brands' : 'models'}/${id}`, {
      method: "DELETE",
      headers: { "Accept":"application/json", "X-CSRF-Token": this.csrf() }
    })
    if (res.status === 204) { window.location.reload(); return }
    const data = await res.json().catch(()=>({}))
    alert(data.error || (type === "brand" ? "No se puede eliminar: tiene modelos asociados" : "No se puede eliminar: tiene artículos asociados"))
  }

  csrf(){ return document.querySelector('meta[name="csrf-token"]')?.content || "" }
}
