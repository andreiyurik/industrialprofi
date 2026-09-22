module CalculatorsHelper
  # Locale-formatted so a seeded default reads like the JS result beside it (0,95 not 0.95).
  # No thousands delimiter — the field is for typing.
  def calculator_value(value)
    return value unless value.is_a?(Numeric)

    number_with_precision(value, precision: 6, strip_insignificant_zeros: true, delimiter: "")
  end
end
