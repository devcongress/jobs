import { Controller } from "@hotwired/stimulus"

// Shows or hides the "item" targets when a checkbox is toggled.
export default class extends Controller {
  static targets = ["item"]

  toggle(event) {
    this.itemTargets.forEach((item) => item.classList.toggle("hidden", !event.target.checked))
  }
}
