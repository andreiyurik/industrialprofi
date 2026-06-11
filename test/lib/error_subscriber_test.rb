require "test_helper"

class ErrorSubscriberTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    # The test env uses :null_store, which can't throttle — swap in a real one.
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @subscriber = ErrorSubscriber.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "emails an unhandled error once per throttle window" do
    error = RuntimeError.new("boom")
    error.set_backtrace([ "app/models/user.rb:1" ])

    assert_enqueued_emails 1 do
      2.times { @subscriber.report(error, handled: false, severity: :error, context: {}) }
    end
  end

  test "ignores handled errors" do
    assert_no_enqueued_emails do
      @subscriber.report(RuntimeError.new("rescued"), handled: true, severity: :warning, context: {})
    end
  end
end
