module ApplicationHelper
  include Heroicon::Engine.helpers

  TOPIC_ICONS = {
    "bolt" => "bolt",
    "fire" => "fire",
    "wrench" => "wrench",
    "cog" => "cog-6-tooth",
    "thermometer" => "beaker",
    "shield" => "shield-check"
  }.freeze

  def topic_icon_svg(name)
    icon = TOPIC_ICONS[name] || TOPIC_ICONS["cog"]
    heroicon(icon, variant: :outline, options: { class: "w-10 h-10" })
  end

  MARKDOWN_TAGS = %w[h1 h2 h3 h4 h5 h6 p ul ol li a strong em code pre blockquote table thead tbody tr th td hr br img].freeze
  MARKDOWN_ATTRS = %w[href src alt target rel].freeze

  def markdown(text)
    return "" if text.blank?
    html = Kramdown::Document.new(text, input: "GFM").to_html
    sanitize(html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRS)
  end

  def russian_pluralize(count, key)
    t("common.#{key}", count: count)
  end
end
