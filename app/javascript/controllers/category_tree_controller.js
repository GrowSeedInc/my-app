import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["children", "arrow"]

  toggle() {
    const isHidden = this.childrenTarget.style.display === "none"
    this.childrenTarget.style.display = isHidden ? "" : "none"
    this.arrowTarget.textContent = isHidden ? "▼" : "▶"
  }
}
