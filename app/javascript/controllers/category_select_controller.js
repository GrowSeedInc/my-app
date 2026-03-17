import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["major", "medium", "minor"]
  static values = {
    mediumsUrl: String,
    minorsUrl: String,
    mode: { type: String, default: "form" },
    selectedMajor: String,
    selectedMedium: String,
    selectedMinor: String
  }

  connect() {
    if (this.selectedMajorValue) {
      this.majorTarget.value = this.selectedMajorValue
      this.fetchMediums(this.selectedMajorValue).then(() => {
        if (this.selectedMediumValue) {
          this.mediumTarget.value = this.selectedMediumValue
          if (this.hasMinorTarget) {
            this.fetchMinors(this.selectedMediumValue).then(() => {
              if (this.selectedMinorValue) {
                this.minorTarget.value = this.selectedMinorValue
              }
              this.updateSubmitState()
            })
          } else {
            this.updateSubmitState()
          }
        } else {
          this.updateSubmitState()
        }
      })
    } else {
      this.updateSubmitState()
    }
  }

  majorChange() {
    const majorId = this.majorTarget.value
    this.clearSelect(this.mediumTarget, "中分類を選択")
    if (this.hasMinorTarget) this.clearSelect(this.minorTarget, "小分類を選択")
    if (majorId) {
      this.fetchMediums(majorId).then(() => this.updateSubmitState())
    } else {
      this.updateSubmitState()
    }
  }

  mediumChange() {
    const mediumId = this.mediumTarget.value
    if (this.hasMinorTarget) this.clearSelect(this.minorTarget, "小分類を選択")
    if (mediumId && this.hasMinorTarget) {
      this.fetchMinors(mediumId).then(() => this.updateSubmitState())
    } else {
      this.updateSubmitState()
    }
  }

  fetchMediums(majorId) {
    const url = `${this.mediumsUrlValue}?major_id=${majorId}`
    return fetch(url, { headers: { Accept: "application/json" } })
      .then(response => response.json())
      .then(data => this.rebuildSelect(this.mediumTarget, data, "中分類を選択"))
  }

  fetchMinors(mediumId) {
    const url = `${this.minorsUrlValue}?medium_id=${mediumId}`
    return fetch(url, { headers: { Accept: "application/json" } })
      .then(response => response.json())
      .then(data => this.rebuildSelect(this.minorTarget, data, "小分類を選択"))
  }

  rebuildSelect(selectEl, options, placeholder) {
    selectEl.innerHTML = `<option value="">${placeholder}</option>`
    options.forEach(({ id, name }) => {
      const option = document.createElement("option")
      option.value = id
      option.textContent = name
      selectEl.appendChild(option)
    })
  }

  clearSelect(selectEl, placeholder) {
    selectEl.innerHTML = `<option value="">${placeholder || "---"}</option>`
  }

  updateSubmitState() {
    if (this.modeValue !== "form") return
    const submitBtn = this.element.closest("form")?.querySelector("[type='submit']")
    if (!submitBtn) return
    if (!this.hasMinorTarget) return
    const minorSelected = this.minorTarget.value !== ""
    submitBtn.disabled = !minorSelected
    submitBtn.classList.toggle("opacity-50", !minorSelected)
    submitBtn.classList.toggle("cursor-not-allowed", !minorSelected)
    submitBtn.classList.toggle("cursor-pointer", minorSelected)
  }
}
