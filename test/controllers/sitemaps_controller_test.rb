require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "sitemap returns XML with correct content type" do
    get "/sitemap.xml"
    assert_response :success
    assert_match %r{application/xml}, response.content_type
  end

  test "sitemap contains published paths" do
    get "/sitemap.xml"
    assert_includes response.body, "/paths/#{paths(:electrician).slug}"
    assert_includes response.body, "/paths/#{paths(:welder).slug}"
  end

  test "sitemap does not contain draft paths" do
    get "/sitemap.xml"
    refute_includes response.body, "/paths/#{paths(:draft_path).slug}"
  end

  test "sitemap contains lessons from published paths" do
    get "/sitemap.xml"
    assert_includes response.body, "/lessons/#{lessons(:pteep).slug}"
  end

  test "sitemap contains static pages" do
    get "/sitemap.xml"
    assert_includes response.body, "https://industrialprofi.com/"
    assert_includes response.body, "https://industrialprofi.com/paths"
    assert_includes response.body, "https://industrialprofi.com/support_us"
  end

  test "sitemap contains the projects landing page" do
    get "/sitemap.xml"
    assert_includes response.body, "https://industrialprofi.com/projects"
  end

  test "sitemap contains lastmod" do
    get "/sitemap.xml"
    assert_includes response.body, "<lastmod>"
  end

  test "sitemap is cached" do
    get "/sitemap.xml"
    assert_response :success
    assert response.headers["Cache-Control"].include?("max-age")
  end

  test "robots welcomes all bots, paces them, hides private areas, and links the sitemap" do
    get "/robots.txt"
    assert_response :success
    assert_match(/User-agent: \*/, response.body)
    assert_match(/Crawl-delay: 10/, response.body)
    assert_match(%r{Disallow: /admin}, response.body)
    assert_match %r{Sitemap: .+/sitemap\.xml}, response.body
    assert_not response.body.match?(%r{^Disallow: /$}), "must not blanket-block the whole site"
  end
end
