import { Controller } from "@hotwired/stimulus"

// The public site's mobile menu: the burger toggles it, Escape or following
// a link closes it.
export default class extends Controller {
  static targets = ["button", "menu"]

  toggle() {
    this.#set(!this.menuTarget.classList.contains("is-open"))
  }

  close() {
    this.#set(false)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  #set(open) {
    this.menuTarget.classList.toggle("is-open", open)
    this.menuTarget.setAttribute("aria-hidden", String(!open))
    this.buttonTarget.setAttribute("aria-expanded", String(open))
    this.buttonTarget.setAttribute("aria-label", open ? "Close menu" : "Open menu")
  }
}
