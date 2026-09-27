import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Cached pages (fresh_when, expires_in) can still carry the banner after dismissal.
  connect() {
    if (document.cookie.split("; ").includes("feedback_banner_dismissed=1")) this.element.remove()
  }

  dismiss() {
    document.cookie = "feedback_banner_dismissed=1; path=/; max-age=31536000; samesite=lax"
    this.element.remove()
  }
}
