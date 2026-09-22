import { Controller } from "@hotwired/stimulus"
import { csrfToken } from "helpers/http_helpers"
import { elementAfter } from "helpers/dom_helpers"

// Native HTML5 drag-and-drop, no library. On drop the final DOM order is persisted;
// the server renumbers and re-files each lesson from where it landed. A no-op drag
// skips the request, and a failed one restores the pre-drop order.
export default class extends Controller {
  static targets = ["courseList", "course", "lessonList", "lesson", "pos", "empty"]
  static values = { lessonsUrl: String, coursesUrl: String, savedText: String, failedText: String }

  #dragType = null
  #block = null
  #dragging = null
  #snapshot = null
  #beforeSignature = null
  #toastEl = null

  // Actions

  dragStart(event) {
    const el = event.target
    if (el.classList?.contains("builder-lesson")) {
      this.#dragType = "lesson"
      this.#block = [el]
    } else if (el.classList?.contains("builder-stage")) {
      this.#dragType = "stage"
      this.#block = this.#stageBlock(el)
    } else if (el.classList?.contains("builder-course")) {
      this.#dragType = "course"
      this.#block = [el]
    } else {
      return
    }
    this.#dragging = el
    this.#block.forEach((node) => node.classList.add("is-dragging"))
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "") // Firefox needs data set to drag

    this.#snapshot = this.#snapshotChildren(this.#dragType)
    this.#beforeSignature = this.#signature(this.#dragType)
  }

  dragOver(event) {
    if (!this.#dragging) return
    event.preventDefault()

    if (this.#dragType === "course") {
      this.#insertBlock(this.courseListTarget, this.#courseAfter(event.clientY))
    } else {
      const list = this.#lessonListUnder(event.clientY)
      if (!list) return
      const anchor = this.#dragType === "stage"
        ? this.#stageAfter(list, event.clientY)
        : this.#lessonAfter(list, event.clientY)
      this.#insertBlock(list, anchor)
      list.querySelector(".builder-course__empty")?.remove()
    }
  }

  drop(event) {
    if (this.#dragging) event.preventDefault()
  }

  dragEnd() {
    if (!this.#dragging) return
    this.#block?.forEach((node) => node.classList.remove("is-dragging"))
    const type = this.#dragType
    this.#dragging = null
    this.#dragType = null
    this.#block = null

    if (this.#signature(type) === this.#beforeSignature) return // dropped back in place

    this.#renumberLessonLabels()
    if (type === "course") {
      this.#persist(this.coursesUrlValue, { course_ids: this.courseTargets.map((c) => c.dataset.courseId) })
    } else {
      this.#persist(this.lessonsUrlValue, { lessons: this.#collectLessons() })
    }
  }

  toggle(event) {
    event.target.closest(".builder-course").classList.toggle("is-collapsed")
  }

  // Private

  // A stage block = the heading plus its contiguous lessons, up to the next heading.
  #stageBlock(heading) {
    const block = [heading]
    let node = heading.nextElementSibling
    while (node && !node.classList.contains("builder-stage")) {
      if (node.classList.contains("builder-lesson")) block.push(node)
      node = node.nextElementSibling
    }
    return block
  }

  #insertBlock(list, anchor) {
    for (const node of this.#block) {
      anchor ? list.insertBefore(node, anchor) : list.appendChild(node)
    }
  }

  // Tags each lesson with its course and the nearest heading's stage.
  #collectLessons() {
    const lessons = []
    this.lessonListTargets.forEach((list) => {
      const courseId = list.dataset.courseId
      let stage = ""
      for (const child of list.children) {
        if (child.classList.contains("builder-stage")) {
          stage = child.dataset.stage || ""
        } else if (child.classList.contains("builder-lesson")) {
          lessons.push({ id: child.dataset.lessonId, course_id: courseId, stage })
        }
      }
    })
    return lessons
  }

  #signature(type) {
    return type === "course"
      ? this.courseTargets.map((c) => c.dataset.courseId).join(",")
      : JSON.stringify(this.#collectLessons())
  }

  // Positions are global within the profession, numbered straight through on-screen order.
  #renumberLessonLabels() {
    let position = 0
    this.lessonListTargets.forEach((list) => {
      list.querySelectorAll(".builder-lesson .builder-lesson__pos").forEach((label) => {
        label.textContent = ++position
      })
    })
  }

  #persist(url, data) {
    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken()
      },
      body: JSON.stringify(data)
    })
      .then((response) => {
        if (!response.ok) throw new Error(response.status)
        this.#toast(this.savedTextValue)
      })
      .catch(() => {
        this.#restoreOrder()
        this.#renumberLessonLabels()
        this.#toast(this.failedTextValue)
      })
  }

  #restoreOrder() {
    if (!this.#snapshot) return
    for (const [list, children] of this.#snapshot) list.append(...children)
  }

  #snapshotChildren(type) {
    const lists = type === "course" ? [this.courseListTarget] : this.lessonListTargets
    return lists.map((list) => [list, [...list.children]])
  }

  // Lives in <body> (not the tree) so it never shifts the list; replaces any earlier pill.
  #toast(text) {
    this.#toastEl?.remove()
    const pill = document.createElement("div")
    pill.className = "flash"
    pill.dataset.controller = "element-removal"
    pill.dataset.elementRemovalDelayValue = "4000"
    const inner = document.createElement("div")
    inner.className = "flash__inner"
    inner.textContent = text
    pill.append(inner)
    document.body.append(pill)
    this.#toastEl = pill
  }

  #lessonListUnder(y) {
    let nearest = null
    let nearestGap = Infinity
    for (const list of this.lessonListTargets) {
      const course = list.closest(".builder-course")
      if (course?.classList.contains("is-collapsed")) continue
      const box = list.getBoundingClientRect()
      if (y >= box.top && y <= box.bottom) return list
      const gap = y < box.top ? box.top - y : y - box.bottom
      if (gap < nearestGap) {
        nearestGap = gap
        nearest = list
      }
    }
    return nearest
  }

  #lessonAfter(list, y) {
    const candidates = Array.from(list.querySelectorAll(".builder-lesson"))
      .filter((item) => !this.#block.includes(item))
    return elementAfter(candidates, y)
  }

  // Anchors only on other headings, so a stage slots between sections, not inside one.
  #stageAfter(list, y) {
    const candidates = Array.from(list.querySelectorAll(".builder-stage"))
      .filter((heading) => !this.#block.includes(heading))
    return elementAfter(candidates, y)
  }

  #courseAfter(y) {
    const candidates = this.courseTargets.filter((item) => item !== this.#dragging)
    return elementAfter(candidates, y)
  }
}
