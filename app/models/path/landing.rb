module Path::Landing
  extend ActiveSupport::Concern

  TEXT_SLOTS = %i[about history faq].freeze
  LIST_SLOTS = %i[highlights pros cons].freeze
  SLOTS = (TEXT_SLOTS + LIST_SLOTS).freeze
  MAX_ITEMS = 10
  MAX_ITEM_LENGTH = 200

  included do
    store_accessor :landing, *SLOTS, :cover_credit
    has_one_attached :cover

    before_validation :normalize_landing
    validate :acceptable_cover
    validate :landing_lists_within_bounds
  end

  LIST_SLOTS.each do |slot|
    define_method(:"#{slot}_text") { Array(public_send(slot)).join("\n") }
    define_method(:"#{slot}_text=") do |text|
      public_send(:"#{slot}=", text.to_s.lines.map(&:strip).compact_blank)
    end
  end

  def landing_present? = SLOTS.any? { |slot| public_send(slot).present? }

  # Fills only an EMPTY landing — a landing with any human text stays as is.
  def fill_landing(data)
    return false if data.blank? || landing.present?

    update!(landing: data)
  end

  # No headings at all means the slot falls back to rendering as plain prose.
  def faq_entries
    faq.to_s.split(/^###[ \t]+/).drop(1).filter_map do |chunk|
      question, answer = chunk.split("\n", 2)
      [ question.strip, answer.to_s.strip ] if question.present?
    end
  end

  class_methods do
    def normalize_landing(data)
      data = data.to_h.stringify_keys
      TEXT_SLOTS.to_h { |slot| [ slot.to_s, data[slot.to_s].to_s.strip.presence ] }
        .merge(LIST_SLOTS.to_h { |slot| [ slot.to_s, Array(data[slot.to_s]).map { |item| item.to_s.strip }.compact_blank.presence ] })
        .merge("cover_credit" => data["cover_credit"].to_s.strip.presence)
        .compact
    end
  end

  private
    def normalize_landing
      self.landing = self.class.normalize_landing(landing)
    end

    def acceptable_cover
      return unless cover.attached?
      return if LessonImageUpload.permits?(content_type: cover.content_type, byte_size: cover.byte_size)

      errors.add(:cover, :invalid)
    end

    def landing_lists_within_bounds
      LIST_SLOTS.each do |slot|
        items = Array(public_send(slot))
        errors.add(slot, :too_long, count: MAX_ITEMS) if items.size > MAX_ITEMS
        errors.add(slot, :invalid) if items.any? { |item| item.length > MAX_ITEM_LENGTH }
      end
    end
end
