require "test_helper"

class DocsWikiTest < ActiveSupport::TestCase
  DOCS = Rails.root.join("docs")
  INDEX = DOCS.join("README.md")
  LINKED_FILES = [ Rails.root.join("AGENTS.md"), *Dir[DOCS.join("**/*.md")] ]

  setup do
    @pages = Dir[DOCS.join("**/*.md")].map { |file| Pathname(file) } - [ INDEX, *Dir[DOCS.join("diagrams/*.excalidraw.md")].map { Pathname(it) } ]
  end

  test "every page has a one-line summary in its frontmatter" do
    missing = @pages.reject { |page| frontmatter(page)["summary"].present? }

    assert_empty missing.map { relative(it) }, "Pages without a frontmatter summary"
  end

  test "every page is listed in the index" do
    listed = links_in(INDEX)
    unlisted = @pages.reject { |page| listed.include?(page) }

    assert_empty unlisted.map { relative(it) }, "Pages missing from docs/README.md"
  end

  test "every paths glob still matches code" do
    stale = @pages.flat_map do |page|
      Array(frontmatter(page)["paths"]).filter_map do |glob|
        "#{relative(page)}: #{glob}" if Dir.glob(Rails.root.join(glob).to_s, File::FNM_EXTGLOB).empty?
      end
    end

    assert_empty stale, "Frontmatter paths that match no file — the page has drifted from the code"
  end

  test "every relative link resolves" do
    broken = LINKED_FILES.flat_map do |file|
      links_in(file).reject(&:exist?).map { "#{relative(file)} → #{relative(it)}" }
    end

    assert_empty broken, "Broken relative links"
  end

  test "every Claude rule points at a convention page" do
    rules = Dir[Rails.root.join(".claude/rules/*.md")].map { |rule| Pathname(rule) }

    rules.each do |rule|
      assert rule.symlink?, "#{relative(rule)} must be a symlink into docs/conventions"
      assert_equal DOCS.join("conventions", rule.basename), rule.realpath
    end
  end

  private
    def frontmatter(page)
      yaml = page.read[/\A---\n(.*?)\n---\n/m, 1]
      yaml ? YAML.safe_load(yaml, permitted_classes: [ Date ]) : {}
    end

    def links_in(file)
      Pathname(file).read.scan(/\]\(([^)\s#]+\.md)(?:#[^)]*)?\)/).flatten
        .reject { it.start_with?("http") }
        .map { Pathname(file).dirname.join(it).expand_path }
    end

    def relative(path)
      Pathname(path).relative_path_from(Rails.root).to_s
    end
end
