require "test_helper"

class JournalEntryTest < ActiveSupport::TestCase
  setup do
    @user = users(:member)
  end

  def build_entry(**attrs)
    @user.journal_entries.new(body: "Собрал щиток по схеме", **attrs)
  end

  def photo_upload
    Rack::Test::UploadedFile.new(file_fixture("photo.png"), "image/png")
  end

  test "valid with body only" do
    assert build_entry.valid?
  end

  test "requires body" do
    entry = @user.journal_entries.new(title: "Без текста")
    assert_not entry.valid?
  end

  test "accepts an image photo" do
    entry = build_entry
    entry.photos.attach(photo_upload)
    assert entry.valid?
  end

  test "rejects more than MAX_PHOTOS photos" do
    entry = build_entry
    (JournalEntry::MAX_PHOTOS + 1).times { entry.photos.attach(photo_upload) }
    assert_not entry.valid?
    assert entry.errors[:photos].any?
  end

  test "rejects non-image attachments" do
    entry = build_entry
    entry.photos.attach(Rack::Test::UploadedFile.new(file_fixture("not_image.txt"), "text/plain"))
    assert_not entry.valid?
  end

  test "rejects a photo over the size limit" do
    entry = build_entry
    entry.photos.attach(photo_upload)
    entry.photos.attachments.first.blob.byte_size = JournalEntry::MAX_PHOTO_SIZE + 1
    assert_not entry.valid?
  end

  test "rejects new photos once the user quota is exhausted" do
    existing = build_entry
    existing.photos.attach(photo_upload)
    existing.save!
    ActiveStorage::Blob.update_all(byte_size: JournalEntry::PHOTO_QUOTA_PER_USER)

    entry = build_entry
    entry.photos.attach(photo_upload)
    assert_not entry.valid?
    assert entry.errors[:photos].any?
  end

  test "mass-assigned photos are optimized to webp on the way in" do
    # The controller path (mass-assignment) runs PhotoOptimizer; `.attach` above
    # is the low-level path that deliberately doesn't. Needs libvips, so it runs
    # in CI and is skipped on a bare dev box.
    skip "libvips not available on this machine" unless PhotoOptimizer::VIPS_AVAILABLE

    entry = build_entry(photos: [ photo_upload ])
    assert_equal "image/webp", entry.photos.first.blob.content_type
  end

  test "destroying a user destroys their entries" do
    build_entry.save!
    assert_difference -> { JournalEntry.count }, -1 do
      @user.destroy
    end
  end
end
