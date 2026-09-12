require "test_helper"

class MapTest < ActiveSupport::TestCase
  setup do
    @map = maps(:expert_map)
  end

  test "one map per user" do
    duplicate = Map.new(user: users(:editor), title: "Вторая")
    assert_not duplicate.valid?
  end

  test "requires a title" do
    assert_not Map.new(user: users(:member), title: " ").valid?
  end

  test "a link item needs a title and an http(s) url; a lesson item needs neither" do
    assert_not @map.items.build(title: "Без адреса").valid?
    assert_not @map.items.build(title: "Не ссылка", url: "javascript:alert(1)").valid?
    assert @map.items.build(title: "Регламент", url: "https://example.com/x").valid?
    assert @map.items.build(lesson: lessons(:zazemlenie), excluded: true).valid?
  end

  test "host strips www and survives a malformed url" do
    assert_equal "example.com", map_items(:expert_link).host
    assert_equal "youtube.com", MapItem.new(url: "https://www.youtube.com/watch?v=1").host
    assert_nil MapItem.new(url: "http://exa mple.com").host
  end

  test "the map is the profession minus what the author took off" do
    assert_equal [ lessons(:pteep), lessons(:gruppy_dopuska) ], @map.lessons
    assert_equal({ courses(:el_basics) => [ lessons(:pteep), lessons(:gruppy_dopuska) ] }, @map.lessons_by_course)
  end

  test "a lesson added to the profession shows up on the map, uncopied" do
    added = courses(:el_basics).lessons.create!(path: paths(:electrician), title: "Новая статья",
                                                slug: "novaya-statya", body: "Текст", position: 9)

    assert_includes @map.reload.lessons, added
    assert_no_difference -> { @map.items.count } do
      @map.choose_lessons!(@map.lessons.map(&:id))
    end
  end

  test "choose_lessons! stores only the difference: keeping everything drops both exclusions" do
    assert_difference -> { @map.items.count }, -2 do
      @map.choose_lessons!(paths(:electrician).lessons.joins(:course).merge(Course.published).ids)
    end
    assert_equal [ "Регламент участка" ], @map.items.reload.select(&:link?).map(&:title), "the link under a kept lesson stays"
    assert_equal "Только главы 1.1–1.4", @map.extras_by_lesson[lessons(:pteep).id].note, "so does the comment on it"
  end

  test "choose_lessons! drops links under a dropped lesson and keeps loose ones" do
    loose = @map.items.create!(title: "Общая", url: "https://example.com/all")
    @map.choose_lessons!([ lessons(:gruppy_dopuska).id ], notes: { lessons(:gruppy_dopuska).id => "до 1.7.60" })

    assert_equal [ lessons(:gruppy_dopuska) ], @map.lessons
    assert_equal [ loose ], @map.items.reload.select(&:link?), "the link under the dropped ПТЭЭП went with it"
    assert_equal "до 1.7.60", @map.extras_by_lesson[lessons(:gruppy_dopuska).id].note
  end

  test "a comment survives only on a lesson the map keeps" do
    @map.choose_lessons!([ lessons(:gruppy_dopuska).id ], notes: { lessons(:pteep).id => "не сохранится" })
    assert_nil @map.extras_by_lesson[lessons(:pteep).id]
  end

  test "extras_by_lesson hangs notes and links under their lesson, loose links under nil" do
    @map.items.create!(title: "Общая", url: "https://example.com/all")
    extras = @map.extras_by_lesson

    assert_equal "Только главы 1.1–1.4", extras[lessons(:pteep).id].note
    assert_equal [ "Регламент участка" ], extras[lessons(:pteep).id].links.map(&:title)
    assert_equal [ "Общая" ], extras[nil].links.map(&:title)
  end

  test "deleting a lesson sets its attached links loose" do
    lessons(:pteep).destroy
    assert_nil map_items(:expert_link).reload.after_lesson_id
  end

  test "progress counts completed lessons among the map's lessons" do
    completed = [ lessons(:pteep).id, lessons(:zazemlenie).id ].to_set # zazemlenie is off the map

    assert_equal 1, @map.completed_count(completed)
    assert_equal 2, @map.lessons.size
    assert_equal 0, @map.completed_count(Set.new)
  end

  test "a follow counts once, never for the author" do
    assert_not @map.follows.build(user: users(:editor)).valid?
    assert_not @map.follows.build(user: users(:member)).valid?
    assert_difference -> { @map.reload.follows_count }, 1 do
      @map.follows.create!(user: users(:admin))
    end
  end

  test "deleting a lesson drops its overlay row; deleting the profession empties the map" do
    item_id = map_items(:expert_pteep).id
    lessons(:pteep).destroy
    assert_nil MapItem.find_by(id: item_id)

    paths(:electrician).destroy
    assert_nil @map.reload.path
    assert_empty @map.lessons
    assert_equal [ "Регламент участка" ], @map.items.map(&:title), "the author's own link survives the cascade"
  end

  test "caps the item count" do
    map = Map.new(user: users(:member), title: "Много")
    (Map::MAX_ITEMS + 1).times { |i| map.items.build(title: "l#{i}", url: "https://e.com/#{i}") }
    assert_not map.valid?
  end
end
