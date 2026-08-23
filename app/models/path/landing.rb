# The profession's «О профессии» landing — the slots every profession in every
# country has (what the work is, what a master can do, strong and weak sides,
# history, the questions newcomers ask) plus one cover image. One JSON column:
# a new slot is code, not a migration, and it is added only when two
# professions ask for it. Anything national or trade-specific (разряды,
# standards, pay, licences) is PROSE inside a slot, never schema — that is what
# keeps one template universal. Two field types only: markdown text and a list
# of one-line items; the admin form is a textarea per slot.
module Path::Landing
  extend ActiveSupport::Concern

  TEXT_SLOTS = %i[about history faq].freeze
  LIST_SLOTS = %i[highlights pros cons].freeze
  SLOTS = (TEXT_SLOTS + LIST_SLOTS).freeze
  MAX_ITEMS = 10
  MAX_ITEM_LENGTH = 200

  included do
    store_accessor :landing, *SLOTS, :cover_credit
    # One committed-size image per profession (readers get resized WebP
    # variants) — bounded by the number of professions, never by users.
    has_one_attached :cover

    before_validation :normalize_landing
    validate :acceptable_cover
    validate :landing_lists_within_bounds
  end

  # The list slots edit as plain textareas, one item per line.
  LIST_SLOTS.each do |slot|
    define_method(:"#{slot}_text") { Array(public_send(slot)).join("\n") }
    define_method(:"#{slot}_text=") do |text|
      public_send(:"#{slot}=", text.to_s.lines.map(&:strip).compact_blank)
    end
  end

  def landing_present? = SLOTS.any? { |slot| public_send(slot).present? }

  # A pack's landing fills an EMPTY one even on a profession a human already
  # owns: nothing human is overwritten, so the import freeze (Importable) has
  # nothing to guard. A landing with any human text stays as it is.
  def fill_landing(data)
    return false if data.blank? || landing.present?

    update!(landing: data)
  end

  # The FAQ slot as [[question, answer_markdown], …]: every `### ` heading
  # opens an entry (the page renders them as native disclosures). Text before
  # the first heading is ignored; no headings at all → [] and the slot renders
  # as plain prose instead.
  def faq_entries
    faq.to_s.split(/^###[ \t]+/).drop(1).filter_map do |chunk|
      question, answer = chunk.split("\n", 2)
      [ question.strip, answer.to_s.strip ] if question.present?
    end
  end

  class_methods do
    # A landing as it arrives from a pack (landing.yml) or a pasted document:
    # only known slots, strings stripped, lists as arrays of non-blank lines.
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
