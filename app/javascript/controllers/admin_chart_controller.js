import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

// Weekly bar chart with a 4-week moving-average trend line overlaid.
export default class extends Controller {
  static values = {
    labels: Array,
    counts: Array,
    label: String,
  }

  connect() {
    this.chart = new Chart(this.element, {
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            type: "bar",
            label: this.labelValue,
            data: this.countsValue,
            backgroundColor: this.#color("--color-link"),
            borderRadius: 3,
            order: 2,
          },
          {
            type: "line",
            label: "Тренд (4 недели)",
            data: this.#movingAverage(this.countsValue, 4),
            borderColor: this.#color("--color-subtle-dark"),
            backgroundColor: "transparent",
            borderWidth: 2,
            pointRadius: 0,
            tension: 0.3,
            order: 1,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        scales: {
          x: {
            grid: { display: false },
            // Horizontal labels, thinned out — diagonal week labels clutter a phone-width chart.
            ticks: { color: this.#color("--color-subtle-dark"), maxRotation: 0, autoSkip: true },
          },
          y: { beginAtZero: true, ticks: { precision: 0, color: this.#color("--color-subtle-dark") } },
        },
        plugins: {
          legend: { display: false },
          tooltip: { boxPadding: 4 },
        },
      },
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  // Private

  #movingAverage(values, window) {
    return values.map((_, i) => {
      const slice = values.slice(Math.max(0, i - window + 1), i + 1)
      return slice.reduce((sum, v) => sum + v, 0) / slice.length
    })
  }

  // Reads a CSS custom property's used value, so the chart follows the OKLCH palette.
  #color(variable) {
    const probe = document.createElement("span")
    probe.style.cssText = `color: var(${variable}); display: none`
    document.body.appendChild(probe)
    const color = getComputedStyle(probe).color
    probe.remove()
    return color
  }
}
