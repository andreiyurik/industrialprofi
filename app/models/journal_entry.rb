class JournalEntry < ApplicationRecord
  # The safety rails that keep a one-server, one-maintainer app alive:
  # a full disk would take down SQLite — and with it the whole site.
  MAX_PHOTOS = 5
  MAX_PHOTO_SIZE = 10.megabytes
  PHOTO_QUOTA_PER_USER = 250.megabytes

  belongs_to :user
  belongs_to :lesson, optional: true

  has_rich_text :body
  has_many_attached :photos

  validates :body, presence: true
  validate :photos_within_limits

  # Shrink + re-encode each uploaded image before it is stored (see
  # PhotoOptimizer). We transform only the file contents and hand the same-shaped
  # list to Active Storage, so attach/replace/blank semantics are unchanged —
  # blanks and non-images pass straight through.
  def photos=(attachables)
    attachables = attachables.map { |a| PhotoOptimizer.optimize(a) } if attachables.is_a?(Array)
    super
  end

  scope :ordered, -> { order(created_at: :desc) }

  # Total bytes of journal photos a user has stored — the quota base.
  def self.photo_bytes_for(user)
    ActiveStorage::Blob
      .joins(:attachments)
      .where(active_storage_attachments: {
        record_type: name, name: "photos", record_id: user.journal_entries.select(:id)
      })
      .sum(:byte_size)
  end

  private
    def photos_within_limits
      blobs = photos.attachments.map(&:blob)

      errors.add(:photos, :too_many, count: MAX_PHOTOS) if blobs.size > MAX_PHOTOS

      blobs.each do |blob|
        errors.add(:photos, :not_image) unless blob.content_type.to_s.start_with?("image/")
        errors.add(:photos, :too_big, megabytes: MAX_PHOTO_SIZE / 1.megabyte) if blob.byte_size.to_i > MAX_PHOTO_SIZE
      end

      new_bytes = blobs.reject(&:persisted?).sum { |blob| blob.byte_size.to_i }
      if new_bytes.positive? && self.class.photo_bytes_for(user) + new_bytes > PHOTO_QUOTA_PER_USER
        errors.add(:photos, :quota_exceeded, megabytes: PHOTO_QUOTA_PER_USER / 1.megabyte)
      end
    end
end
