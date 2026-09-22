// @ts-check
import CalculatorController from "controllers/calculator_controller"

// Кнопка берёт у браузера широту, долготу и часовой пояс разом — «введите то,
// чего вы не знаете» и есть главный способ потерять пользователя.
export default class extends CalculatorController {
  // Формула зовётся явно: у собственного контроллера нет data-calculator-formula-value.
  paint(input) {
    this.render(this.goldenHour(input))
  }

  locate() {
    if (!navigator.geolocation) return this.#fail()

    this.element.dataset.locating = "true"
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        this.#fill("lat", this.num(coords.latitude, 4))
        this.#fill("lon", this.num(coords.longitude, 4))
        // Смещение браузер отдаёт в минутах и с обратным знаком.
        this.#fill("tz", this.num(-new Date().getTimezoneOffset() / 60, 1))
        delete this.element.dataset.locating
        this.compute()
      },
      () => this.#fail()
    )
  }

  // Private

  #fail() {
    this.element.dataset.locating = "failed"
  }

  #fill(field, value) {
    const input = this.element.querySelector(`[data-field="${field}"]`)
    if (input) input.value = value
  }
}
