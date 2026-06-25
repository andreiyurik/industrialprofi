require "test_helper"

class MailMetricsTest < ActiveSupport::TestCase
  # The test env uses :null_store (counting is a no-op there), so swap in a real
  # in-memory store to exercise the actual read/write behaviour.
  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown { Rails.cache = @original_cache }

  test "record_delivery increments today's counter" do
    assert_equal 0, MailMetrics.sent_last(7)
    3.times { MailMetrics.record_delivery }
    assert_equal 3, MailMetrics.sent_last(7)
  end

  test "sent_last sums across the window and excludes older days" do
    MailMetrics.record_delivery(on: Date.current)
    MailMetrics.record_delivery(on: Date.current - 6)   # inside a 7-day window
    MailMetrics.record_delivery(on: Date.current - 10)  # outside it

    assert_equal 2, MailMetrics.sent_last(7)
    assert_equal 1, MailMetrics.sent_last(1)            # today only
  end

  test "the deliver.action_mailer subscription feeds the counter" do
    assert_difference -> { MailMetrics.sent_last(7) }, 1 do
      ActiveSupport::Notifications.instrument("deliver.action_mailer") { :sent }
    end
  end

  test "a broken cache never raises into delivery" do
    Rails.cache = Class.new(ActiveSupport::Cache::Store) do
      def read_entry(*) = raise("cache down")
      def write_entry(*) = raise("cache down")
    end.new

    assert_nil MailMetrics.record_delivery
    assert_nil MailMetrics.sent_last(7)
  end
end
