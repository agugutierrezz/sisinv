import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["brandModal", "modelModal", "personModal", "brandSelectInModel"]
  static values  = { modelsUrl: String }

  connect() {
    // buscas dentro del contenedor del controller
    this.brandSelect  = this.element.querySelector('select[name="article[marca_id]"]')
    this.modelSelect  = this.element.querySelector('select[name="article[modelo_id]"]')
    this.personSelect = this.element.querySelector('select[name="article[persona_actual_id]"]')
    this.syncBrandsToModelModal()
    this.filterModelsForCurrentBrand()
  }

  async onBrandChange() {
    this.syncBrandsToModelModal()
    await this.filterModelsForCurrentBrand()
  }

  async filterModelsForCurrentBrand() {
    if (!this.modelSelect) return
    const brandId = this.brandSelect?.value || ""
    await this.fetchAndPopulateModels(brandId)
  }

  async fetchAndPopulateModels(brandId) {
    try {
      this.setModelOptions([{ id: "", nombre: "Cargando...", anio: "" }], "")
      const url = brandId ? `/models/for_brand?marca_id=${encodeURIComponent(brandId)}`
                          : `/models/for_brand`
      const res = await fetch(url, { headers: { "Accept": "application/json" } })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error || "No se pudieron cargar los modelos")

      const selected = this.modelSelect?.dataset.selected || this.modelSelect?.value || ""
      this.setModelOptions(data, selected)
    } catch (err) {
      alert(err.message)
      this.setModelOptions([], "")
    }
  }

  setModelOptions(models, selectedId = "") {
    if (!this.modelSelect) return
    this.modelSelect.innerHTML = ""
    this.modelSelect.add(new Option("Seleccionar", ""))
    for (const m of models) {
      const label = `${m.nombre} ${m.anio || ""}`.trim()
      const opt   = new Option(label, m.id, false, String(m.id) === String(selectedId))
      this.modelSelect.add(opt)
    }
  }
  
  open(e) {
    const type = e.currentTarget.dataset.modalFormTypeValue
    if (type === "brand") this.brandModalTarget.showModal()
    if (type === "model") { this.syncBrandsToModelModal(); this.modelModalTarget.showModal() }
    if (type === "person") this.personModalTarget.showModal()
  }
  close() {
    this.brandModalTarget?.close()
    this.modelModalTarget?.close()
    this.personModalTarget?.close()
  }

  syncBrandsToModelModal() {
    if (!this.brandSelect || !this.hasBrandSelectInModelTarget) return
    const sel = this.brandSelectInModelTarget
    const value = this.brandSelect.value
    sel.innerHTML = ""
    for (const opt of this.brandSelect.options) {
      if (!opt.value) continue
      sel.add(new Option(opt.textContent, opt.value))
    }
    if (value) sel.value = value
  }

  csrf() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  async createBrand(ev) {
    ev.preventDefault()
    const form = ev.currentTarget
    const nombre = form.nombre.value.trim()
    if (!nombre) return
    const res = await fetch("/brands/create_modal", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": this.csrf() },
      body: JSON.stringify({ nombre })
    })
    const data = await res.json()
    if (!res.ok) { alert(data.error || "Error creando marca"); return }
    this.appendOption(this.brandSelect, data.id, data.nombre, { select: true })
    this.syncBrandsToModelModal()
    this.close()
  }

  async createModel(ev) {
    ev.preventDefault()
    const form = ev.currentTarget
    const payload = { marca_id: form.marca_id.value, nombre: form.nombre.value.trim(), anio: form.anio.value }
    const res = await fetch("/models/create_modal", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": this.csrf() },
      body: JSON.stringify(payload)
    })
    const data = await res.json()
    if (!res.ok) { alert(data.error || "Error creando modelo"); return }
    this.appendOption(this.modelSelect, data.id, `${data.nombre} ${data.anio || ""}`.trim(), { select: true })
    this.close()
  }

  async createPerson(ev) {
    ev.preventDefault()
    const form = ev.currentTarget
    const payload = { nombre: form.nombre.value.trim(), apellido: form.apellido.value.trim(), identificador: form.identificador.value.trim() }
    const res = await fetch("/people/create_modal", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": this.csrf() },
      body: JSON.stringify(payload)
    })
    const data = await res.json()
    if (!res.ok) { alert(data.error || "Error creando persona"); return }
    this.appendOption(this.personSelect, data.id, `${data.nombre} ${data.apellido}`, { select: true })
    this.close()
  }

  appendOption(select, value, text, { select: sel=false } = {}) {
    if (!select) return
    const opt = new Option(text, value, sel, sel)
    select.add(opt)
    if (sel) select.dispatchEvent(new Event("change"))
  }
}
