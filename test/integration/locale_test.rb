require "test_helper"

# The locale prefix is canonical: /ru/... and /en/... are the only URLs Google
# should ever index, old unprefixed links 301 into /ru, and each piece of
# content lives in exactly one locale.
class LocaleTest < ActionDispatch::IntegrationTest
  test "an unprefixed GET redirects permanently to its /ru twin" do
    get "/about"

    assert_redirected_to "/ru/about"
    assert_response :moved_permanently
  end

  test "the redirect keeps the query string" do
    get "/resources?path=svarshchik"

    assert_redirected_to "/ru/resources?path=svarshchik"
  end

  test "robots and sitemap stay at the domain root" do
    get "/robots.txt"

    assert_response :success
    assert_includes response.body, "Disallow: /ru/admin"
    assert_includes response.body, "Disallow: /en/admin"
  end

  test "the English catalog renders with the English prefix" do
    get "/en"

    assert_response :success
  end

  test "content requested under the wrong locale goes home" do
    lesson = lessons(:pteep)
    get "/en/lessons/#{lesson.slug}"

    assert_redirected_to "/ru/lessons/#{lesson.slug}"
    assert_response :moved_permanently
  end

  test "pages advertise their language twins to crawlers" do
    get "/ru/about"

    assert_response :success
    assert_includes response.body, %(rel="alternate" hreflang="en" href="http://www.example.com/en/about")
    assert_includes response.body, %(hreflang="x-default")
  end

  test "content pages carry no hreflang pairs" do
    lesson = lessons(:pteep)
    get "/ru/lessons/#{lesson.slug}"

    assert_response :success
    assert_not_includes response.body, %(rel="alternate" hreflang=)
  end
end
