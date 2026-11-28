# Animated lesson schemes: curated ERB + CSS in the repo, placed as `![alt](diagram:<slug>)`.
class Diagram
  SLUGS = %w[
    current-loop
    switch-circuits
    plc-scan
    rcd-leak
    cabinet-signal
    ld-ton
    pid-response
    rs485-modbus
    fault-loop
    packet-route
    osi-layers
  ].freeze
  STATIC = %w[cabinet-signal rs485-modbus].freeze
  SRC = /\Adiagram:(?<slug>[a-z0-9-]+)\z/
  SLOT = "diagram-slot"

  def self.slug(src)
    slug = Lesson.decode_placeholder(src)[SRC, :slug]
    slug if SLUGS.include?(slug)
  end

  def self.embed(html)
    return html unless html.include?(Lesson.encode_placeholder("diagram:"))

    fragment = Nokogiri::HTML5.fragment(html)
    figures = fragment.css("img[src]").filter_map do |image|
      if (name = slug(image["src"]))
        yield name, lift(image)
      end
    end
    # Spliced as text: reparsing the drawings would rewrite their markup.
    fragment.to_html.gsub("<#{SLOT}></#{SLOT}>") { figures.shift }
  end

  # Rendered lessons are cached, and template digests don't reach a helper cache.
  def self.version
    @version = nil if Rails.env.development?
    @version ||= Digest::MD5.hexdigest(
      Dir[Rails.root.join("{app/views/diagrams/*,config/locales/diagrams/*}")].sort.map { File.read(it) }.join)
  end

  def self.lift(image)
    # A figure can't live inside a paragraph or an attachment.
    block = image.ancestors.take_while { %w[p figure action-text-attachment].include?(it.name) }.last || image
    caption = take_caption(image, block)
    block.add_next_sibling(image.document.create_element(SLOT))
    (block == image || only_image?(block, image) ? block : image).remove
    caption
  end

  def self.only_image?(block, image)
    rest = block.dup
    rest.css("img, em, figcaption, br").each(&:remove)
    rest.text.strip.empty? && block.css("img").to_a == [ image ]
  end

  def self.take_caption(image, block)
    own = adjacent_caption(image) || block.at_css("figcaption") unless block == image
    following = block.next_element
    own ||= following if following&.name == "p" && following.elements.map(&:name) == [ "em" ] &&
      following.text.strip == following.at_css("em").text.strip
    return unless own

    caption = (own.at_css("em") || own).inner_html
    own.remove
    caption.html_safe
  end

  def self.adjacent_caption(image)
    node = image.next_sibling
    node = node.next_sibling while node&.text? && node.text.blank?
    if node&.name == "br"
      node = node.next_sibling
      node = node.next_sibling while node&.text? && node.text.blank?
    end
    node if node&.name == "em"
  end
  private_class_method :lift, :only_image?, :take_caption, :adjacent_caption
end
