require "test_helper"

class IndexNowJobTest < ActiveSupport::TestCase
  test "payload carries host, key, keyLocation and the URL list" do
    urls = [ "https://industrialprofi.com/paths/elektrik" ]
    payload = IndexNowJob.payload(urls, "abc123")

    assert_equal "industrialprofi.com", payload[:host]
    assert_equal "abc123", payload[:key]
    assert_equal "https://industrialprofi.com/abc123.txt", payload[:keyLocation]
    assert_equal urls, payload[:urlList]
  end

  test "perform is a safe no-op when no key is configured" do
    # No INDEXNOW_KEY in test → returns before any network call.
    assert_nothing_raised do
      IndexNowJob.new.perform([ "https://industrialprofi.com/x" ])
    end
  end
end
