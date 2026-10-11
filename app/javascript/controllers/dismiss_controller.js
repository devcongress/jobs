import { Controller } from "@hotwired/stimulus"

// Hides a card for good: remembers the dismissal in a cookie the server checks.
export default class extends Controller {
  static values = { cookie: String }

  dismiss() {
    document.cookie = `${this.cookieValue}=1; max-age=31536000; path=/; samesite=lax`
    this.element.remove()
  }
}
