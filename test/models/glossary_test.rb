require "test_helper"

class GlossaryTest < ActiveSupport::TestCase
  test "groups follow published paths and resolve lessons where slugs exist" do
    groups = Glossary.grouped

    assert groups.any?, "the electrician glossary should surface (fixture path slug = elektrik)"
    path, terms = groups.first
    assert_equal "elektrik", path.slug
    assert terms.any?
    # Fixture DB doesn't hold the real curriculum, so lesson links resolve to
    # nil and the page falls back to search — the registry must not blow up.
    assert terms.all? { |term| term.lesson.nil? || term.lesson.is_a?(Lesson) }
  end

  # Content guard: a malformed entry should fail here, not 500 in production.
  test "every registry entry is well-formed and unique within its group" do
    data = YAML.load_file(Rails.root.join("config/glossary.yml"))

    data.each do |group, entries|
      abbrs = entries.map { |entry| entry.fetch("term") }
      assert_equal abbrs.uniq, abbrs, "duplicate terms in #{group}"
      entries.each do |entry|
        assert entry.fetch("full").present?, "#{group}/#{entry["term"]} lacks расшифровка"
      end
    end
  end
end
