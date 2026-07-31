// @ts-check
import CalculatorController from "controllers/calculator_controller"

// Своих координат человек наизусть не знает, а без них калькулятор эфемерид
// бесполезен — «введите то, чего вы не знаете» и есть главный способ потерять
// пользователя. Кнопка берёт у браузера широту, долготу и часовой пояс разом:
// три поля, которые иначе пришлось бы выяснять на стороне.
export default class extends CalculatorController {
  // Эфемериды считает та же формула в базе; своим контроллер стал ради кнопки,
  // а не ради математики. Формулу зовём явно: имя приходило из
  // data-calculator-formula-value, которого у собственного контроллера нет.
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
