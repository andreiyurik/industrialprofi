require "test_helper"

class DiagramRenderingTest < ActionView::TestCase
  include ApplicationHelper
  include Admin::EditorHelper

  test "a diagram image becomes its scheme with the caption under it" do
    figure = Nokogiri::HTML5.fragment(markdown("![Петля](diagram:current-loop)\n*Токовая петля*")).at_css("figure.diagram-current-loop")

    assert figure.at_css("svg")
    assert_equal "Токовая петля", figure.at_css("figcaption").text.strip
  end

  test "a caption in its own paragraph joins the figure" do
    page = Nokogiri::HTML5.fragment(markdown("![a](diagram:plc-scan)\n\n*Подпись*"))

    assert_equal "Подпись", page.at_css("figure.diagram > figcaption").text.strip
  end

  test "text around a diagram stays in its paragraph" do
    page = Nokogiri::HTML5.fragment(markdown("До ![a](diagram:plc-scan) после"))

    assert page.at_css("p + figure.diagram")
    assert_empty page.css("p figure")
  end

  test "the caption survives a trip through the rich editor" do
    rich = ActionText::Content.new(editor_html("![a](diagram:plc-scan)\n*Подпись*"))
    page = Nokogiri::HTML5.fragment(enrich_prose(rich.to_s))

    assert_equal "Подпись", page.at_css("figure.diagram > figcaption").text.strip
    assert_empty page.css("p figure, action-text-attachment figure")
  end

  test "an unknown diagram stays out of the page" do
    assert_no_match(/<svg|diagram:/, markdown("![Нет](diagram:nope)"))
  end

  test "every diagram placed in the curriculum exists" do
    slugs = Dir[Rails.root.join("db/seeds/curriculum/**/*.md")].flat_map { File.read(it).scan(/\]\(diagram:([^)]+)\)/) }.flatten

    assert_empty slugs - Diagram::SLUGS
  end
end
