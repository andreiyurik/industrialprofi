# Auto-generates a URL slug from the title when one isn't given — so in-app
# authors don't have to hand-transliterate Cyrillic. Only fires on create, so
# existing slugs (which URLs and re-import keys depend on) can never auto-change.
# A typed slug is respected as-is; an auto slug is de-duplicated with -2, -3…
module Sluggable
  extend ActiveSupport::Concern

  TRANSLITERATIONS = {
    "а" => "a", "б" => "b", "в" => "v", "г" => "g", "д" => "d", "е" => "e",
    "ё" => "e", "ж" => "zh", "з" => "z", "и" => "i", "й" => "y", "к" => "k",
    "л" => "l", "м" => "m", "н" => "n", "о" => "o", "п" => "p", "р" => "r",
    "с" => "s", "т" => "t", "у" => "u", "ф" => "f", "х" => "h", "ц" => "ts",
    "ч" => "ch", "ш" => "sh", "щ" => "sch", "ъ" => "", "ы" => "y", "ь" => "",
    "э" => "e", "ю" => "yu", "я" => "ya"
  }.freeze

  included do
    before_validation :generate_slug, on: :create
  end

  class_methods do
    def slugify(text)
      text.to_s.downcase.chars.map { |char| TRANSLITERATIONS.fetch(char, char) }.join
          .gsub(/[^a-z0-9]+/, "-").gsub(/-+/, "-").delete_prefix("-").delete_suffix("-")
    end
  end

  private
    def generate_slug
      return if slug.present? || title.blank?

      base = self.class.slugify(title)
      return if base.blank?

      candidate = base
      suffix = 2
      while self.class.exists?(slug: candidate)
        candidate = "#{base}-#{suffix}"
        suffix += 1
      end
      self.slug = candidate
    end
end
