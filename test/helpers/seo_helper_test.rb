require "test_helper"

class SeoHelperTest < ActionView::TestCase
  test "learning_resource_json_ld returns valid JSON-LD for lesson" do
    lesson = lessons(:pteep)
    result = learning_resource_json_ld(lesson)
    assert_includes result, '"@type":"LearningResource"'
    assert_includes result, lesson.title
    assert_includes result, "IndustrialProfi"
  end

  test "course_json_ld returns valid JSON-LD for path" do
    path = paths(:electrician)
    result = course_json_ld(path)
    assert_includes result, '"@type":"Course"'
    assert_includes result, path.title
    assert_includes result, '"isAccessibleForFree":true'
  end

  test "website_json_ld returns valid JSON-LD" do
    result = website_json_ld
    assert_includes result, '"@type":"WebSite"'
    assert_includes result, "IndustrialProfi"
  end

  test "breadcrumb_json_ld returns valid BreadcrumbList" do
    crumbs = [
      { title: "Профессии", url: "https://industrialprofi.com/paths" },
      { title: "Электрик", url: "https://industrialprofi.com/paths/elektrik" }
    ]
    result = breadcrumb_json_ld(crumbs)
    assert_includes result, '"@type":"BreadcrumbList"'
    assert_includes result, "Профессии"
    assert_includes result, "Электрик"
  end
end
