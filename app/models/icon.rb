# The icon set is assets, not data — so the list of what an expert may choose
# comes from the files themselves, and there is nothing to keep in sync.
#
# Emblems are the `-light` weight: they're the only ones rendered at 32px and up
# (profession/chapter circles), which is where a filled glyph needs the lighter
# cut to sit level with our type. See icons.css.
class Icon
  DIR = Rails.root.join("app/assets/images/icons")
  EMBLEM_SUFFIX = "-light"
  DEFAULT_EMBLEM = "wrench#{EMBLEM_SUFFIX}".freeze

  class << self
    def emblems
      @emblems ||= DIR.glob("*#{EMBLEM_SUFFIX}.svg").map { it.basename(".svg").to_s }.sort
    end

    def emblem?(name)
      emblems.include?(name)
    end
  end
end
