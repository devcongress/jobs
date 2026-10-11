import { Controller } from "@hotwired/stimulus"

// Copies a value to the clipboard and briefly confirms it.
export default class extends Controller {
  static targets = ["label"]
  static values = { text: String }

  async copy() {
    await navigator.clipboard.writeText(this.textValue)
    const original = this.labelTarget.textContent
    this.labelTarget.textContent = "Copied!"
    setTimeout(() => { this.labelTarget.textContent = original }, 1500)
  }
}
