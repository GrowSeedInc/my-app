import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "panel", "scrim", "main", "hamburger" ]

  connect() {
    this.applyState(this._resolveInitialState())
  }

  toggle() {
    this._isOpen() ? this.close() : this.open()
  }

  open() {
    this.applyState(true)
    this.saveState(true)
  }

  close() {
    this.applyState(false)
    this.saveState(false)
  }

  handleWindowClick(event) {
    if (window.matchMedia("(min-width: 1024px)").matches) return
    if (!this._isOpen()) return
    if (this.panelTarget.contains(event.target)) return
    if (this.hamburgerTarget.contains(event.target)) return
    this.close()
  }

  applyState(isOpen) {
    if (isOpen) {
      this.panelTarget.classList.remove("-translate-x-full")
      this.panelTarget.classList.add("translate-x-0")
      this.scrimTarget.classList.remove("hidden")
      this.mainTarget.classList.remove("lg:ml-0")
      this.mainTarget.classList.add("lg:ml-64")
      this.hamburgerTarget.setAttribute("aria-expanded", "true")
    } else {
      this.panelTarget.classList.remove("translate-x-0")
      this.panelTarget.classList.add("-translate-x-full")
      this.scrimTarget.classList.add("hidden")
      this.mainTarget.classList.remove("lg:ml-64")
      this.mainTarget.classList.add("lg:ml-0")
      this.hamburgerTarget.setAttribute("aria-expanded", "false")
    }
  }

  saveState(isOpen) {
    localStorage.setItem("sidebarOpen", isOpen ? "true" : "false")
  }

  restoreState() {
    const value = localStorage.getItem("sidebarOpen")
    if (value === null) return null
    return value === "true"
  }

  _resolveInitialState() {
    const saved = this.restoreState()
    if (saved !== null) return saved
    return window.matchMedia("(min-width: 1024px)").matches
  }

  _isOpen() {
    return this.hamburgerTarget.getAttribute("aria-expanded") === "true"
  }
}
