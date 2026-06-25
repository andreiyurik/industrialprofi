require "test_helper"

class IndexNowNotifiableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "no ping when no IndexNow key is configured" do
    assert_no_enqueued_jobs only: IndexNowJob do
      paths(:electrician).update!(title: "Электрик — новое название")
    end
  end

  test "pings IndexNow when a published path's content changes" do
    with_indexnow_key do
      assert_enqueued_with(job: IndexNowJob) do
        paths(:electrician).update!(title: "Электрик 2")
      end
    end
  end

  test "non-content changes (position) do not ping" do
    with_indexnow_key do
      assert_no_enqueued_jobs only: IndexNowJob do
        paths(:electrician).update!(position: paths(:electrician).position + 5)
      end
    end
  end

  test "a draft path is never pinged (no public URL)" do
    assert_nil paths(:draft_path).send(:indexnow_url)

    with_indexnow_key do
      assert_no_enqueued_jobs only: IndexNowJob do
        paths(:draft_path).update!(title: "Черновик 2")
      end
    end
  end

  private
    def with_indexnow_key
      site = Rails.application.config.x.site
      site.indexnow_key = "test-key"
      yield
    ensure
      site.indexnow_key = nil
    end
end
