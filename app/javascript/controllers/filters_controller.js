import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["brandSelect", "modelSelect", "loader"]

  connect() {
    const marcaId = this.brandSelectTarget?.value
    if (marcaId) this.loadModels(marcaId, this.currentModeloId())

    // ocultar loader al terminar de renderizar el frame
    this.onFrameLoad = (e) => { if (e.target.id === "articles_list") this.hideLoader() }
    document.addEventListener("turbo:frame-load", this.onFrameLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.onFrameLoad)
  }

  async onBrandChange(event) {
    const marcaId = event.target.value
    await this.loadModels(marcaId)  // repuebla modelos según marca
    this.autosubmit()               // y recién ahí aplica filtro
  }

  autosubmit() {
    this.showLoader()
    this.element.requestSubmit()    // GET al frame articles_list
  }

  clear() {
    if (this.hasBrandSelectTarget) this.brandSelectTarget.value = ""
    if (this.hasModelSelectTarget) {
      this.modelSelectTarget.innerHTML = `<option value="">Todos</option>`
      this.modelSelectTarget.disabled = false
    }
    const desde = this.element.querySelector('input[name="fecha_desde"]'); if (desde) desde.value = ""
    const hasta = this.element.querySelector('input[name="fecha_hasta"]'); if (hasta) hasta.value = ""
    this.autosubmit()
  }

  currentModeloId() {
    const params = new URLSearchParams(window.location.search)
    return params.get("modelo_id") || ""
  }

  async loadModels(marcaId, keepSelectionId = "") {
    const url = marcaId ? `/models.json?marca_id=${encodeURIComponent(marcaId)}` : `/models.json`

    try {
      if (this.hasModelSelectTarget) {
        this.modelSelectTarget.disabled = true
        this.modelSelectTarget.innerHTML = `<option value="">Cargando…</option>`
      }

      const resp = await fetch(url, { headers: { "Accept": "application/json" } })
      const data = await resp.json()

      const opts = [`<option value="">Todos</option>`]
      for (const m of data) {
        const selected = keepSelectionId && String(m.id) === String(keepSelectionId) ? " selected" : ""
        opts.push(`<option value="${m.id}"${selected}>${m.nombre}</option>`)
      }

      if (this.hasModelSelectTarget) {
        this.modelSelectTarget.innerHTML = opts.join("")
        this.modelSelectTarget.disabled = false
      }
    } catch (e) {
      console.error("Error cargando modelos:", e)
      if (this.hasModelSelectTarget) {
        this.modelSelectTarget.innerHTML = `<option value="">Todos</option>`
        this.modelSelectTarget.disabled = false
      }
    }
  }

  showLoader() { if (this.hasLoaderTarget) this.loaderTarget.classList.remove("hidden") }
  hideLoader() { if (this.hasLoaderTarget) this.loaderTarget.classList.add("hidden") }
}
