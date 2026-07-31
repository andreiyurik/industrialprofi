module CalculatorsHelper
  # A seeded field value printed the way this locale writes numbers, so a
  # default reads the same as the result the JS prints beside it ("0,95", not
  # "0.95" next to "10,53"). No thousands delimiter — the field is for typing.
  def calculator_value(value)
    return value unless value.is_a?(Numeric)

    number_with_precision(value, precision: 6, strip_insignificant_zeros: true, delimiter: "")
  end
end
