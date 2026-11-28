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

  test "a separate caption paragraph survives the rich editor and stays the figcaption" do
    rich = ActionText::Content.new(editor_html("![Длинное описание схемы](diagram:plc-scan)\n\n*Подпись*"))
    page = Nokogiri::HTML5.fragment(enrich_prose(rich.to_s))

    assert_equal [ "Подпись" ], page.css("figcaption").map { it.text.strip }
    assert_empty page.css("p em")
  end

  test "an emphasis elsewhere in the paragraph is not taken as the caption" do
    page = Nokogiri::HTML5.fragment(markdown("Смотри *внимательно* на схему ![a](diagram:plc-scan) ниже"))

    assert_includes page.at_css("p").inner_html, "<em>внимательно</em>"
    assert_nil page.at_css("figure.diagram > figcaption")
  end

  test "an image-only paragraph leaves no empty paragraph behind" do
    page = Nokogiri::HTML5.fragment(markdown("![a](diagram:plc-scan)"))

    assert page.at_css("figure.diagram")
    assert page.css("p").none? { it.text.strip.empty? && it.elements.empty? }
  end

  test "the same diagram twice on a page keeps its radio groups and svg defs apart" do
    page = Nokogiri::HTML5.fragment(markdown("![a](diagram:current-loop)\n\n![a](diagram:current-loop)\n\n![a](diagram:plc-scan)\n\n![a](diagram:plc-scan)"))
    names = page.css("input[type=radio]").map { it["name"] }.uniq
    ids = page.css("svg [id]").map { it["id"] }

    assert_equal 2, names.size
    assert_equal ids.uniq, ids
  end

  test "an unknown diagram is dropped without a pending box" do
    html = markdown("![Нет](diagram:nope)\n\nТекст")

    assert_no_match(/<svg|diagram:|prose-figure|<img/, html)
    assert_match "Текст", html
  end

  test "every diagram placed in the curriculum exists" do
    slugs = Dir[Rails.root.join("db/seeds/curriculum/**/*.md")].flat_map { File.read(it).scan(/\]\(diagram:([^)]+)\)/) }.flatten

    assert_empty slugs - Diagram::SLUGS
  end
end
