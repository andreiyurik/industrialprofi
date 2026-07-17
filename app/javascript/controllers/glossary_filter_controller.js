import { Controller } from "@hotwired/stimulus"

// Live filter for the glossary: pure DOM, zero requests — every entry is
// already server-rendered, we only toggle [hidden]. Two axes compose: a text
// query (word-prefix matching — «узо» must find УЗО, not «нагрУЗОк») and a
// script toggle (все / русскоязычные / международные) that shows or hides
// whole subgroups. A group hides when nothing inside it survives; the empty
// state links a fruitless query out to full-text search.
export default class extends Controller {
  static targets = [ "entry", "group", "subgroup", "empty", "searchLink", "scriptTab" ]

  #query = ""
  #script = "all"
  #words = new WeakMap()

  // Actions

  filter(event) {
    this.#query = event.target.value
    this.#apply()
  }

  setScript(event) {
    this.#script = event.params.script
    for (const tab of this.scriptTabTargets) {
      tab.setAttribute("aria-pressed", tab === event.currentTarget ? "true" : "false")
    }
    this.#apply()
  }

  // Private

  #apply() {
    const tokens = this.#tokenize(this.#query)

    for (const entry of this.entryTargets) {
      entry.hidden = tokens.length > 0 &&
        !tokens.every(token => this.#wordsOf(entry).some(word => word.startsWith(token)))
    }
    for (const subgroup of this.subgroupTargets) {
      subgroup.hidden = (this.#script !== "all" && subgroup.dataset.script !== this.#script) ||
        !subgroup.querySelector("[data-glossary-filter-target='entry']:not([hidden])")
    }
    for (const group of this.groupTargets) {
      group.hidden = !group.querySelector("[data-glossary-filter-target='subgroup']:not([hidden])")
    }

    const nothingFound = this.groupTargets.every(group => group.hidden)
    this.emptyTarget.hidden = !nothingFound
    if (nothingFound) {
      this.searchLinkTarget.hidden = tokens.length === 0
      this.searchLinkTarget.href = `/search?q=${encodeURIComponent(this.#query.trim())}`
    }
  }

  #tokenize(text) {
    return text.toLowerCase().split(/[^\p{L}\p{N}-]+/u).filter(Boolean)
  }

  #wordsOf(entry) {
    if (!this.#words.has(entry)) {
      this.#words.set(entry, this.#tokenize(entry.dataset.text))
    }
    return this.#words.get(entry)
  }
}
