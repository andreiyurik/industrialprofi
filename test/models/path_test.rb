require "test_helper"

class PathTest < ActiveSupport::TestCase
  # Validations

  test "valid with required attributes" do
    path = Path.new(title: "Токарь", slug: "tokar", status: "published")
    assert path.valid?
  end

  test "invalid without title" do
    path = Path.new(slug: "no-title", status: "published")
    assert_not path.valid?
    assert path.errors[:title].any?
  end

  test "invalid without slug" do
    path = Path.new(title: "No Slug", status: "published")
    assert_not path.valid?
    assert path.errors[:slug].any?
  end

  test "slug must be unique" do
    path = Path.new(title: "Другой электрик", slug: paths(:electrician).slug, status: "published")
    assert_not path.valid?
    assert path.errors[:slug].any?
  end

  test "slug rejects invalid format" do
    %w[UPPER with_underscore кириллица .dot -leading trailing-].each do |bad_slug|
      path = Path.new(title: "Test", slug: bad_slug, status: "published")
      assert_not path.valid?, "Expected slug '#{bad_slug}' to be invalid"
    end
  end

  test "slug accepts valid format" do
    %w[tokar-test my-path abc-123 a].each do |good_slug|
      path = Path.new(title: "Test", slug: good_slug, status: "published")
      assert path.valid?, "Expected slug '#{good_slug}' to be valid, got: #{path.errors.full_messages}"
    end
  end

  test "invalid with unknown status" do
    path = Path.new(title: "Bad", slug: "bad-status", status: "archived")
    assert_not path.valid?
    assert path.errors[:status].any?
  end

  test "position must be non-negative" do
    path = Path.new(title: "Test", slug: "neg-pos", status: "published", position: -1)
    assert_not path.valid?
    assert path.errors[:position].any?
  end

  # Scopes

  test ".published returns only published paths" do
    published = Path.published
    assert_includes published, paths(:electrician)
    assert_includes published, paths(:welder)
    assert_not_includes published, paths(:draft_path)
  end

  test ".official returns paths without author" do
    official = Path.official
    assert_includes official, paths(:electrician)
    assert_not_includes official, paths(:draft_path)
  end

  test ".community returns paths with author" do
    community = Path.community
    assert_includes community, paths(:draft_path)
    assert_not_includes community, paths(:electrician)
  end

  test ".ordered sorts by position" do
    ordered = Path.ordered.to_a
    positions = ordered.map(&:position)
    assert_equal positions.sort, positions
  end

  # Associations

  test "has many lessons" do
    assert_equal 4, paths(:electrician).lessons.count
  end

  test "has many courses" do
    assert_equal 3, paths(:electrician).courses.count
  end

  test "destroying path destroys lessons" do
    assert_difference "Lesson.count", -4 do
      paths(:electrician).destroy
    end
  end

  test "destroying path destroys courses" do
    assert_difference "Course.count", -3 do
      paths(:electrician).destroy
    end
  end

  # Counter cache

  test "lessons_count tracks lesson creation" do
    path = Path.create!(title: "Тест", slug: "test-cc", status: "published")
    assert_equal 0, path.lessons_count
    course = path.courses.create!(title: "Курс", slug: "test-cc-course", position: 1)
    course.lessons.create!(title: "Урок 1", slug: "cc-1", position: 1)
    assert_equal 1, path.reload.lessons_count
  end

  test "courses_count tracks course creation" do
    path = Path.create!(title: "Тест2", slug: "test-cc2", status: "published")
    assert_equal 0, path.courses_count
    path.courses.create!(title: "Курс", slug: "test-cc2-course", position: 1)
    assert_equal 1, path.reload.courses_count
  end

  # to_param

  test "to_param returns slug" do
    assert_equal "elektrik", paths(:electrician).to_param
  end
end
