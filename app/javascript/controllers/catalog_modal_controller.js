import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["brandDialog","brandTitle","brandId","brandName",
                    "modelDialog","modelTitle","modelId","modelBrand","modelName","modelYear" ]

  connect(){
    this.element.__openBrand  = (p={}) => this.openBrand(p)
    this.element.__openModel  = (p={}) => this.openModel(p)
  }

  openBrand({ id, name }={}){
    this.brandTitleTarget.textContent = id ? "Editar marca" : "Nueva marca"
    this.brandIdTarget.value = id || ""
    this.brandNameTarget.value = name || ""
    this.brandDialogTarget.showModal()
  }
  closeBrand(){ this.brandDialogTarget.close() }

  async saveBrand(e){
    e.preventDefault()
    const id = this.brandIdTarget.value
    const nombre = this.brandNameTarget.value.trim()
    if (!nombre) return
    if (id){
      await fetch(`/brands/${id}`, { method:"PATCH", headers:this.h(), body:JSON.stringify({ nombre }) })
    } else {
      await fetch(`/brands/create_modal`, { method:"POST", headers:this.h(), body:JSON.stringify({ nombre }) })
    }
    window.location.reload()
  }

  async openModel({ id, name, year, brandId }={}){
    this.modelTitleTarget.textContent = id ? "Editar modelo" : "Nuevo modelo"
    this.modelIdTarget.value = id || ""
    this.modelNameTarget.value = name || ""
    this.modelYearTarget.value = year || ""
    // cargar marcas en el select
    const res = await fetch("/brands/list", { headers: { "Accept":"application/json" } })
    const brands = await res.json()
    this.modelBrandTarget.innerHTML = `<option value="">Marca…</option>` +
      brands.map(b => `<option value="${b.id}" ${String(b.id)===String(brandId)?'selected':''}>${b.nombre}</option>`).join("")
    this.modelDialogTarget.showModal()
  }
  closeModel(){ this.modelDialogTarget.close() }

  async saveModel(e){
    e.preventDefault()
    const id = this.modelIdTarget.value
    const payload = {
      nombre: this.modelNameTarget.value.trim(),
      marca_id: this.modelBrandTarget.value,
      anio: this.modelYearTarget.value || null
    }
    if (!payload.nombre || !payload.marca_id) return

    if (id){
      await fetch(`/models/${id}`, { method:"PATCH", headers:this.h(), body:JSON.stringify(payload) })
    } else {
      await fetch(`/models/create_modal`, { method:"POST", headers:this.h(), body:JSON.stringify(payload) })
    }
    window.location.reload()
  }

  h(){ return { "Content-Type":"application/json", "Accept":"application/json", "X-CSRF-Token": this.csrf() } }
  csrf(){ return document.querySelector('meta[name="csrf-token"]')?.content || "" }
}
