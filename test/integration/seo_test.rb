require "test_helper"

class SeoTest < ActionDispatch::IntegrationTest
  # ── Meta tags ──

  test "lesson page has canonical link" do
    get lesson_path(lessons(:pteep))
    assert_select 'link[rel="canonical"]'
  end

  test "lesson page has og:title" do
    get lesson_path(lessons(:pteep))
    assert_select 'meta[property="og:title"]'
  end

  test "lesson page has og:description" do
    get lesson_path(lessons(:pteep))
    assert_select 'meta[property="og:description"]'
  end

  test "lesson page has JSON-LD LearningResource" do
    get lesson_path(lessons(:pteep))
    assert_select 'script[type="application/ld+json"]'
    assert_includes response.body, "LearningResource"
  end

  test "path page has JSON-LD Course" do
    get path_path(paths(:electrician))
    assert_select 'script[type="application/ld+json"]'
    assert_includes response.body, '"@type":"Course"'
  end

  test "home page has JSON-LD WebSite" do
    get root_path
    assert_select 'script[type="application/ld+json"]'
    assert_includes response.body, '"@type":"WebSite"'
  end

  test "home page has JSON-LD Organization for brand recognition" do
    get root_path
    assert_includes response.body, '"@type":"EducationalOrganization"'
  end

  test "path page has canonical link" do
    get path_path(paths(:electrician))
    assert_select 'link[rel="canonical"]'
  end

  test "home page has canonical link" do
    get root_path
    assert_select 'link[rel="canonical"]'
  end

  test "lesson page has twitter card meta" do
    get lesson_path(lessons(:pteep))
    assert_select 'meta[name="twitter:card"]'
  end

  test "lesson page has robots meta" do
    get lesson_path(lessons(:pteep))
    assert_select 'meta[name="robots"]'
  end

  test "path page has breadcrumb JSON-LD" do
    get path_path(paths(:electrician))
    assert_includes response.body, "BreadcrumbList"
  end

  # ── robots.txt ──

  test "robots.txt contains sitemap" do
    get "/robots.txt"
    assert_response :success
    assert_includes response.body, "Sitemap:"
    assert_includes response.body, "industrialprofi.com/sitemap.xml"
  end
end
