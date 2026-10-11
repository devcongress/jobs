import { Controller } from "@hotwired/stimulus"

// Closes a <details> dropdown on outside click or Escape.
export default class extends Controller {
  connect() {
    this.onClick = (event) => { if (!this.element.contains(event.target)) this.element.open = false }
    this.onKey = (event) => { if (event.key === "Escape") this.element.open = false }
    document.addEventListener("click", this.onClick)
    document.addEventListener("keydown", this.onKey)
  }

  disconnect() {
    document.removeEventListener("click", this.onClick)
    document.removeEventListener("keydown", this.onKey)
  }
}
