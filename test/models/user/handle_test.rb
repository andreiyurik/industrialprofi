require "test_helper"

class User::HandleTest < ActiveSupport::TestCase
  test "handle is lowercased, slug-shaped, unique and optional" do
    user = users(:member)
    user.update!(handle: " Ivan-Petrov ")
    assert_equal "ivan-petrov", user.handle

    assert_not user.update(handle: "иван")
    assert_not user.update(handle: "ab")
    assert_not user.update(handle: "expert")
    assert user.update(handle: "")
    assert_nil user.handle
  end

  test "ensure_handle! transliterates the name and de-duplicates" do
    assert_equal "ivan", users(:member).ensure_handle!
    twin = User.create!(name: "Иван", email_address: "twin@example.com", password: "password123")
    assert_equal "ivan-2", twin.ensure_handle!
    assert_equal "ivan-2", twin.ensure_handle!, "idempotent"
  end

  test "a handle cannot be cleared while a map exists, but it can be renamed" do
    assert_not users(:editor).update(handle: "")

    assert users(:editor).update(handle: "master-ivan")
    assert_equal "master-ivan", maps(:expert_map).reload.to_param, "the shared link follows the address"
  end

  test "deleting an account takes its map, items and follows with it" do
    assert_difference [ -> { Map.count }, -> { MapFollow.count } ], -1 do
      assert_difference -> { MapItem.count }, -4 do
        users(:editor).destroy
      end
    end
  end

  test "taking someone's map and then losing the account leaves the map alone" do
    assert_difference -> { MapFollow.count }, -1 do
      assert_no_difference -> { Map.count } do
        users(:member).destroy
      end
    end
  end

  test "profile? needs a handle and good standing" do
    assert users(:editor).profile?
    assert_not users(:member).profile?
    users(:editor).suspend!
    assert_not users(:editor).reload.profile?
  end

  test "improved_lessons lists lessons with an accepted edit or source, once each" do
    member = users(:member)
    lesson_suggestions(:approved_suggestion).update_columns(user_id: member.id)

    assert_includes member.improved_lessons, lessons(:pteep)
    assert_equal member.improved_lessons.to_a.uniq, member.improved_lessons.to_a
    assert_empty users(:admin).improved_lessons
  end
end
