import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  timer = null

  debouncedSearch() {
    clearTimeout(this.timer)
    const val = this.inputTarget.value.trim()
    this.timer = setTimeout(() => {
      const frame = document.querySelector("turbo-frame#people_list")
      if (!frame) return

      const url = new URL(window.location)
      // desde 2 letras filtramos; menos, limpiamos
      if (val.length >= 2) url.searchParams.set("q", val)
      else url.searchParams.delete("q")
      url.searchParams.delete("page")

      // sólo recargamos el frame
      frame.src = url.pathname + url.search
    }, 250)
  }
}
