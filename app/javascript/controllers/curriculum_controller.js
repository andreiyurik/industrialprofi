import { Controller } from "@hotwired/stimulus"

// The curriculum builder tree: drag to reorder lessons, whole stages (a heading
// plus its lessons), and whole courses — within a course and across courses.
// Native HTML5 drag-and-drop, no library — same house style as
// nested_form_controller. On drop we persist the final DOM order; the server
// renumbers positions (global within the path) and re-files each lesson's course
// and stage from where it landed, so a stage moved as a block needs no special
// server handling (its lessons simply follow their heading).
//
// The save is resilient: a no-op drag (dropped back in place) skips the request,
// and a failed request restores the pre-drag order so the tree never lies about
// what's stored. A lesson's stage is derived from the nearest preceding stage
// heading in its list, so a heading moved with its lessons keeps them together.
export default class extends Controller {
  static targets = ["courseList", "course", "lessonList", "lesson", "pos", "empty"]
  static values = { lessonsUrl: String, coursesUrl: String, savedText: String, failedText: String }

  dragStart(event) {
    const el = event.target
    if (el.classList?.contains("builder-lesson")) {
      this.dragType = "lesson"
      this.block = [el]
    } else if (el.classList?.contains("builder-stage")) {
      this.dragType = "stage"
      this.block = this.stageBlock(el)
    } else if (el.classList?.contains("builder-course")) {
      this.dragType = "course"
      this.block = [el]
    } else {
      return
    }
    this.dragging = el
    this.block.forEach((node) => node.classList.add("is-dragging"))
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "") // Firefox needs data set to drag

    this.snapshot = this.snapshotChildren(this.dragType)
    this.beforeSignature = this.signature(this.dragType)
  }

  dragOver(event) {
    if (!this.dragging) return
    event.preventDefault()

    if (this.dragType === "course") {
      this.insertBlock(this.courseListTarget, this.courseAfter(event.clientY))
    } else {
      const list = this.lessonListUnder(event.clientY)
      if (!list) return
      const anchor = this.dragType === "stage"
        ? this.stageAfter(list, event.clientY)
        : this.lessonAfter(list, event.clientY)
      this.insertBlock(list, anchor)
      list.querySelector(".builder-course__empty")?.remove()
    }
  }

  drop(event) {
    if (this.dragging) event.preventDefault()
  }

  dragEnd() {
    if (!this.dragging) return
    this.block?.forEach((node) => node.classList.remove("is-dragging"))
    const type = this.dragType
    this.dragging = null
    this.dragType = null
    this.block = null

    if (this.signature(type) === this.beforeSignature) return // dropped back in place

    this.renumberLessonLabels()
    if (type === "course") {
      this.persist(this.coursesUrlValue, { course_ids: this.courseTargets.map((c) => c.dataset.courseId) })
    } else {
      this.persist(this.lessonsUrlValue, { lessons: this.collectLessons() })
    }
  }

  toggle(event) {
    event.target.closest(".builder-course").classList.toggle("is-collapsed")
  }

  // --- block assembly ---

  // A stage block = the heading plus its contiguous lessons, up to the next
  // heading. These move together so a whole section can be re-filed at once.
  stageBlock(heading) {
    const block = [heading]
    let node = heading.nextElementSibling
    while (node && !node.classList.contains("builder-stage")) {
      if (node.classList.contains("builder-lesson")) block.push(node)
      node = node.nextElementSibling
    }
    return block
  }

  insertBlock(list, anchor) {
    for (const node of this.block) {
      anchor ? list.insertBefore(node, anchor) : list.appendChild(node)
    }
  }

  // --- order collection ---

  // Every lesson in on-screen order, tagged with the course it now sits under
  // and the stage of the nearest heading above it.
  collectLessons() {
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

  signature(type) {
    return type === "course"
      ? this.courseTargets.map((c) => c.dataset.courseId).join(",")
      : JSON.stringify(this.collectLessons())
  }

  // Positions are global within the profession, so the visible numbers run
  // straight through the courses in their on-screen order.
  renumberLessonLabels() {
    let position = 0
    this.lessonListTargets.forEach((list) => {
      list.querySelectorAll(".builder-lesson .builder-lesson__pos").forEach((label) => {
        label.textContent = ++position
      })
    })
  }

  // --- persistence (with revert-on-failure) ---

  persist(url, data) {
    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify(data)
    })
      .then((response) => {
        if (!response.ok) throw new Error(response.status)
        this.toast(this.savedTextValue)
      })
      .catch(() => {
        this.restoreOrder()
        this.renumberLessonLabels()
        this.toast(this.failedTextValue)
      })
  }

  restoreOrder() {
    if (!this.snapshot) return
    for (const [list, children] of this.snapshot) list.append(...children)
  }

  snapshotChildren(type) {
    const lists = type === "course" ? [this.courseListTarget] : this.lessonListTargets
    return lists.map((list) => [list, [...list.children]])
  }

  // A floating pill, reusing the app's flash look + element-removal auto-dismiss.
  // Lives in <body> (not the tree) so it never shifts the list and stays in view
  // at any scroll position. Replaces any earlier pill so rapid saves don't stack.
  toast(text) {
    this.toastEl?.remove()
    const pill = document.createElement("div")
    pill.className = "flash"
    pill.dataset.controller = "element-removal"
    pill.dataset.elementRemovalDelayValue = "4000"
    const inner = document.createElement("div")
    inner.className = "flash__inner"
    inner.textContent = text
    pill.append(inner)
    document.body.append(pill)
    this.toastEl = pill
  }

  // --- geometry helpers ---

  lessonListUnder(y) {
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

  lessonAfter(list, y) {
    return Array.from(list.querySelectorAll(".builder-lesson"))
      .filter((item) => !this.block.includes(item))
      .find((item) => {
        const box = item.getBoundingClientRect()
        return y < box.top + box.height / 2
      })
  }

  // A stage block anchors only on other headings (or the list end), so it slots
  // between sections instead of splitting one.
  stageAfter(list, y) {
    return Array.from(list.querySelectorAll(".builder-stage"))
      .filter((heading) => !this.block.includes(heading))
      .find((heading) => {
        const box = heading.getBoundingClientRect()
        return y < box.top + box.height / 2
      })
  }

  courseAfter(y) {
    return this.courseTargets
      .filter((item) => item !== this.dragging)
      .find((item) => {
        const box = item.getBoundingClientRect()
        return y < box.top + box.height / 2
      })
  }
}
