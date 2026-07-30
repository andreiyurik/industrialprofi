require "test_helper"

class IconTest < ActiveSupport::TestCase
  test "emblems come from the light-weight files on disk" do
    assert_includes Icon.emblems, "lightning-light"
    assert Icon.emblems.all? { it.end_with?(Icon::EMBLEM_SUFFIX) }
    assert_not_includes Icon.emblems, "check", "служебные глифы не эмблемы"
  end

  test "emblem? guards what an expert may choose" do
    assert Icon.emblem?("gauge-light")
    assert_not Icon.emblem?("welding-light"), "имени нет в наборе"
    assert_not Icon.emblem?("")
  end
end

class PathIconTest < ActiveSupport::TestCase
  setup { @path = paths(:electrician) }

  test "falls back to the default emblem when unset" do
    @path.update!(icon: nil)
    assert_equal Icon::DEFAULT_EMBLEM, @path.emblem
    assert_nil @path.icon, "фолбэк не пишется в базу"
  end

  test "an expert's pick wins" do
    @path.update!(icon: "atom-light")
    assert_equal "atom-light", @path.emblem
  end

  test "refuses an emblem that has no file" do
    @path.icon = "welding-light"
    assert_not @path.valid?
    assert_includes @path.errors[:icon].join, "недопустимое"
  end

  test "blank is allowed — it means «inherit / default»" do
    @path.icon = ""
    assert @path.valid?
  end
end

class CourseIconTest < ActiveSupport::TestCase
  setup { @course = courses(:el_basics) }

  test "inherits the profession's emblem when unset" do
    @course.update!(icon: nil)
    @course.path.update!(icon: "lightning-light")
    assert_equal "lightning-light", @course.emblem
  end

  test "inheritance follows the profession's own fallback" do
    @course.update!(icon: nil)
    @course.path.update!(icon: nil)
    assert_equal Icon::DEFAULT_EMBLEM, @course.emblem
  end

  test "its own emblem wins over the profession's" do
    @course.path.update!(icon: "lightning-light")
    @course.update!(icon: "toolbox-light")
    assert_equal "toolbox-light", @course.emblem
  end

  test "inheriting does not query the profession again" do
    path = paths(:electrician)
    path.update!(icon: "lightning-light")
    path.courses.each { it.update!(icon: nil) }

    courses = path.courses.reload.to_a
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      courses.each(&:emblem)
    end
    assert_equal 0, queries, "inverse_of должен отдавать уже загруженную профессию"
  end

  test "refuses an emblem that has no file" do
    @course.icon = "not-a-real-icon"
    assert_not @course.valid?
  end
end
