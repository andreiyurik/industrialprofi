// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { subnet, toDottedQuad } from "calculators/math/kipia"
import { EMPTY } from "calculators/format"

// Линейка из 32 бит адреса. Префикс — это буквально граница на ней: слева
// закрашенные биты сети, справа пустые биты хостов. Тяните ползунок префикса —
// и «/24» перестаёт быть заклинанием: видно, сколько бит уходит сети и почему
// хостов остаётся именно столько.
const BITS = 32
const OCTETS = 4

export default class extends CalculatorController {
  paint(input) {
    const result = subnet(input)

    this.render({
      network: result.network == null ? EMPTY : `${toDottedQuad(result.network)}/${result.prefix}`,
      mask: toDottedQuad(result.mask) ?? EMPTY,
      wildcard: toDottedQuad(result.wildcard) ?? EMPTY,
      broadcast: toDottedQuad(result.broadcast) ?? EMPTY,
      hostmin: toDottedQuad(result.hostmin) ?? EMPTY,
      hostmax: toDottedQuad(result.hostmax) ?? EMPTY,
      hosts: this.num(result.hosts, 0)
    })
    this.#draw(result)
  }

  // Private

  #draw(result) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const { prefix, ip, mask } = result
    diagram.dataset.state = prefix == null ? "empty" : "ok"

    diagram.querySelectorAll("[data-bit]").forEach((cell, bit) => {
      cell.dataset.state = prefix == null ? "empty" : bit < prefix ? "net" : "host"
    })

    const figures = {}
    for (let octet = 0; octet < OCTETS; octet++) {
      figures[`address-${octet}`] = this.#octet(ip, octet)
      figures[`mask-${octet}`] = this.#octet(mask, octet)
    }
    this.label(figures)
  }

  #octet(value, index) {
    if (value == null) return EMPTY
    return String((value >>> (BITS - 8 - index * 8)) & 255)
  }
}
