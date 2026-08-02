require "test_helper"

# application.scss is a hand-kept list of every stylesheet, and dartsass builds
# only what that list names. Forget a line and the file simply stops shipping:
# no error, no failing view — just a page missing part of its styling. This is
# the tripwire for that.
class StylesheetManifestTest < ActiveSupport::TestCase
  STYLESHEETS = Rails.root.join("app/assets/stylesheets")
  MANIFEST = STYLESHEETS.join("application.scss")

  setup do
    @listed = MANIFEST.read.scan(/^@use\s+"([^"]+)"/).flatten
    @present = Dir[STYLESHEETS.join("*.css")].map { |file| File.basename(file, ".css") }
  end

  test "every stylesheet is listed in the manifest" do
    missing = @present - @listed

    assert_empty missing,
      "Не попали в application.scss (не будут собраны): #{missing.map { |n| "#{n}.css" }.join(', ')}"
  end

  test "the manifest lists nothing that does not exist" do
    dangling = @listed - @present

    assert_empty dangling, "В application.scss есть строки без файлов: #{dangling.join(', ')}"
  end

  # The build has no cascade layers — file order IS specificity, and it used to
  # be Propshaft's filename-alphabetical order. Keeping the list sorted keeps
  # that contract, so moving to a bundle can never reshuffle who wins.
  test "the manifest stays in alphabetical order" do
    assert_equal @listed.sort, @listed,
      "Порядок в application.scss = порядок каскада; список должен быть по алфавиту"
  end
end
