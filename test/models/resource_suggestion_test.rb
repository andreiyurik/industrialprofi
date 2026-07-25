require "test_helper"

class ResourceSuggestionTest < ActiveSupport::TestCase
  setup { @lesson = lessons(:pteep) }

  test "valid with url, title, kind and author" do
    suggestion = @lesson.resource_suggestions.new(
      author_name: "Иван", url: "https://ya.ru/doc", title: "ГОСТ 1", kind: "norm"
    )
    assert suggestion.valid?
  end

  test "requires a url" do
    suggestion = @lesson.resource_suggestions.new(author_name: "И", title: "T", kind: "norm")
    assert_not suggestion.valid?
    assert suggestion.errors.key?(:url)
  end

  test "rejects a non-http url" do
    suggestion = @lesson.resource_suggestions.new(author_name: "И", url: "ftp://x", title: "T", kind: "norm")
    assert_not suggestion.valid?
  end

  test "rejects an unknown kind" do
    suggestion = @lesson.resource_suggestions.new(author_name: "И", url: "https://x.ru", title: "T", kind: "meme")
    assert_not suggestion.valid?
  end

  test "into_resource! creates a human, optional resource at the end of the list" do
    suggestion = @lesson.resource_suggestions.create!(
      author_name: "И", url: "https://x.ru/d", title: "Док", kind: "article", note: "гл.2"
    )

    resource = nil
    assert_difference -> { @lesson.resources.count }, 1 do
      resource = suggestion.into_resource!
    end

    assert_equal "human", resource.origin
    assert_not resource.required
    assert_equal "гл.2", resource.note
    assert_equal "article", resource.kind
    assert_equal @lesson.resources.maximum(:position), resource.position
  end
end
