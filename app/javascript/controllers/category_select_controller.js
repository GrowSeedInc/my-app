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

      // 中分類の選択肢がサーバーサイドで描画済みの場合はAJAXを呼ばず値のみセット
      const mediumPreloaded = this.hasMediumTarget && this.mediumTarget.options.length > 1

      if (mediumPreloaded) {
        if (this.selectedMediumValue) {
          this.mediumTarget.value = this.selectedMediumValue
        }
        if (this.hasMinorTarget && this.selectedMediumValue) {
          this.fetchMinors(this.selectedMediumValue).then(() => {
            if (this.selectedMinorValue) {
              this.minorTarget.value = this.selectedMinorValue
            }
          })
        }
      } else {
        this.fetchMediums(this.selectedMajorValue).then(() => {
          if (this.selectedMediumValue) {
            this.mediumTarget.value = this.selectedMediumValue
            if (this.hasMinorTarget) {
              this.fetchMinors(this.selectedMediumValue).then(() => {
                if (this.selectedMinorValue) {
                  this.minorTarget.value = this.selectedMinorValue
                }
              })
            }
          }
        })
      }
    }
  }

  majorChange() {
    const majorId = this.majorTarget.value
    this.clearSelect(this.mediumTarget, "中分類を選択")
    if (this.hasMinorTarget) this.clearSelect(this.minorTarget, "小分類を選択")
    if (majorId) {
      this.fetchMediums(majorId)
    }
  }

  minorChange() {}

  mediumChange() {
    const mediumId = this.mediumTarget.value
    if (this.hasMinorTarget) this.clearSelect(this.minorTarget, "小分類を選択")
    if (mediumId && this.hasMinorTarget) {
      this.fetchMinors(mediumId)
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
}
