require "test_helper"

class JournalEntryTest < ActiveSupport::TestCase
  setup do
    @user = users(:member)
  end

  def build_entry(**attrs)
    @user.journal_entries.new(body: "Собрал щиток по схеме", **attrs)
  end

  test "valid with body only" do
    assert build_entry.valid?
  end

  test "requires body" do
    entry = @user.journal_entries.new(title: "Без текста")
    assert_not entry.valid?
  end

  test "destroying a user destroys their entries" do
    build_entry.save!
    assert_difference -> { JournalEntry.count }, -1 do
      @user.destroy
    end
  end
end
