require "test_helper"

# www is served only to be sent away — one canonical host for search engines,
# and no 404 for anyone who types the prefix out of habit.
class WwwRedirectTest < ActionDispatch::IntegrationTest
  CANONICAL = Rails.application.config.x.site.url

  test "the bare domain sends the visitor to the default locale" do
    get "/"

    assert_redirected_to "/ru"
    assert_response :moved_permanently
    follow_redirect!

    assert_response :success
  end

  test "www redirects permanently to the bare domain" do
    get "http://www.industrialprofi.com/"

    assert_response :moved_permanently
    assert_equal "#{CANONICAL}/", response.location
  end

  test "www keeps the path and the query string" do
    get "http://www.industrialprofi.com/resources?path=svarshchik"

    assert_response :moved_permanently
    assert_equal "#{CANONICAL}/resources?path=svarshchik", response.location
  end

  test "www redirects even where no route exists, instead of 404ing" do
    get "http://www.industrialprofi.com/lessons/whatever-slug"

    assert_response :moved_permanently
    assert_equal "#{CANONICAL}/lessons/whatever-slug", response.location
  end

  test "a POST to www is redirected too, not dropped" do
    post "http://www.industrialprofi.com/session"

    assert_response :moved_permanently
    assert_equal "#{CANONICAL}/session", response.location
  end
end
