require "test_helper"

# en.yml must never silently fall behind ru.yml: a missing key would render
# Russian through the i18n fallback on an English page. Plural groups are
# compared as one unit — Russian legitimately has one/few/many/other where
# English has one/other.
class LocalesParityTest < ActiveSupport::TestCase
  PLURAL_KEYS = %w[zero one two few many other].freeze

  test "every ru key exists in en and vice versa" do
    ru = leaf_keys(load_locale("ru"))
    en = leaf_keys(load_locale("en"))

    assert_empty ru - en, "keys missing from en.yml"
    assert_empty en - ru, "keys in en.yml that ru.yml doesn't have"
  end

  private
    def load_locale(locale)
      YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale)
    end

    def leaf_keys(hash, prefix = [])
      hash.flat_map do |key, value|
        next [ (prefix + [ key ]).join(".") ] unless value.is_a?(Hash)

        if value.any? && (value.keys - PLURAL_KEYS).empty?
          [ (prefix + [ key ]).join(".") ]
        else
          leaf_keys(value, prefix + [ key ])
        end
      end
    end
end
