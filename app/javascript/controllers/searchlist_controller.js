import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "list"]

  filter() {
    const q = (this.queryTarget.value || "").trim().toLowerCase()
    this.listTarget.querySelectorAll("[data-name]").forEach(el => {
      const hay = (el.dataset.name || "").toLowerCase()
      el.style.display = (!q || hay.includes(q)) ? "" : "none"
    })
  }
}
