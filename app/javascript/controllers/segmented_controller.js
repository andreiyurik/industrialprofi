import { Controller } from "@hotwired/stimulus"

// A segmented control that toggles between named panels client-side (no reload).
// Each tab and panel carries data-view; clicking a tab shows its panel and
// hides the rest. Used by the suggestion-moderation comparison (side-by-side vs
// inline diff).
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: String }

  connect() {
    this.show(this.activeValue || this.tabTargets[0]?.dataset.view)
  }

  select(event) {
    this.show(event.currentTarget.dataset.view)
  }

  show(view) {
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.view !== view })
    this.tabTargets.forEach((tab) => tab.classList.toggle("is-active", tab.dataset.view === view))
  }
}
