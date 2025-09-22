import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  async submit(e) {
    e.preventDefault()
    const fd = new FormData(this.formTarget)
    const id = fd.get("id")
    const payload = { persona: { nombre: fd.get("nombre"), apellido: fd.get("apellido"), identificador: fd.get("identificador") } }

    try {
      const res = await fetch(id ? `/api/v1/people/${id}` : `/api/v1/people`, {
        method: id ? "PUT" : "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${window.API_TOKEN || ""}`
        },
        body: JSON.stringify(payload)
      })
      if (!res.ok) {
        const txt = await res.text()
        throw new Error(txt || "Error guardando la persona")
      }
      window.location = "/people"
    } catch (err) {
      alert(err.message)
    }
  }
}
