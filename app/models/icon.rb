# Icon set is assets, not data — the list of choosable icons comes from the files themselves.
# Emblems are the -light weight: the only one rendered at 32px+ (profession/chapter circles); see icons.css.
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
