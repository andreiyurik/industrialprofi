require "test_helper"

class ResourceTest < ActiveSupport::TestCase
  # Validations

  test "valid with required attributes" do
    resource = Resource.new(lesson: lessons(:pteep), title: "Документ", url: "https://example.com")
    assert resource.valid?
  end

  test "invalid without title" do
    resource = Resource.new(lesson: lessons(:pteep), url: "https://example.com")
    assert_not resource.valid?
    assert resource.errors[:title].any?
  end

  test "url is optional (a resource may be a title-only reference)" do
    resource = Resource.new(lesson: lessons(:pteep), title: "Документ")
    assert resource.valid?
  end

  test "invalid with non-http url" do
    resource = Resource.new(lesson: lessons(:pteep), title: "Bad", url: "javascript:alert(1)")
    assert_not resource.valid?
    assert resource.errors[:url].any?
  end

  test "invalid with plain text url" do
    resource = Resource.new(lesson: lessons(:pteep), title: "Bad", url: "not-a-url")
    assert_not resource.valid?
    assert resource.errors[:url].any?
  end

  test "accepts http url" do
    resource = Resource.new(lesson: lessons(:pteep), title: "OK", url: "http://example.com")
    assert resource.valid?
  end

  test "invalid without lesson" do
    resource = Resource.new(title: "Orphan", url: "https://example.com")
    assert_not resource.valid?
    assert resource.errors[:lesson].any?
  end

  test "invalid with unknown kind" do
    resource = Resource.new(lesson: lessons(:pteep), title: "Bad", url: "https://example.com", kind: "podcast")
    assert_not resource.valid?
    assert resource.errors[:kind].any?
  end

  test "accepts the explicit taxonomy kinds" do
    %w[norm book doc course video article software tool].each do |kind|
      resource = Resource.new(lesson: lessons(:pteep), title: "OK", url: "https://example.com", kind: kind)
      assert resource.valid?, "#{kind} should be a valid kind"
    end
  end

  # Language marker (orthogonal to kind)

  test "language is optional (nil = Russian)" do
    resource = Resource.new(lesson: lessons(:pteep), title: "OK", url: "https://example.com")
    assert resource.valid?
    assert_nil resource.language
  end

  test "accepts a known foreign language and rejects an unknown one" do
    ok = Resource.new(lesson: lessons(:pteep), title: "OK", url: "https://example.com", language: "en")
    assert ok.valid?
    bad = Resource.new(lesson: lessons(:pteep), title: "Bad", url: "https://example.com", language: "fr")
    assert_not bad.valid?
    assert bad.errors[:language].any?
  end

  test "blank language is normalised to nil" do
    resource = Resource.new(lesson: lessons(:pteep), title: "OK", url: "https://example.com", language: "")
    assert resource.valid?
    assert_nil resource.language
  end

  # Scopes

  test ".required returns only required resources" do
    required = Resource.required
    assert_includes required, resources(:pteep_doc)
    assert_not_includes required, resources(:pteep_article)
  end

  test ".optional returns only optional resources" do
    optional = Resource.optional
    assert_includes optional, resources(:pteep_article)
    assert_not_includes optional, resources(:pteep_doc)
  end

  test ".for_country returns universal and matching resources" do
    ru_resources = Resource.for_country("RU")
    assert_includes ru_resources, resources(:pteep_doc)
    assert_includes ru_resources, resources(:universal_video)
  end

  # Associations

  test "belongs to lesson" do
    assert_equal lessons(:pteep), resources(:pteep_doc).lesson
  end

  # Defaults

  test "kind defaults to document" do
    resource = Resource.new
    assert_equal "document", resource.kind
  end

  test "required defaults to false" do
    resource = Resource.new
    assert_equal false, resource.required
  end
end
