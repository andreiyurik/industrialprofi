require "test_helper"

class AdminActionTest < ActiveSupport::TestCase
  test "records an actor, action and denormalized details" do
    entry = AdminAction.create!(actor: users(:admin), action: "user_role_changed",
      target: users(:member), details: { subject: "Иван", from: "member", to: "editor" })

    assert_equal users(:admin), entry.actor
    assert_equal users(:member), entry.target
    assert_equal "editor", entry.details["to"]
  end

  test "is immutable once persisted" do
    entry = AdminAction.create!(actor: users(:admin), action: "user_role_changed")
    assert entry.readonly?
    assert_raises(ActiveRecord::ReadOnlyRecord) { entry.update!(action: "tampered") }
  end

  test "ordered returns newest first" do
    old = AdminAction.create!(actor: users(:admin), action: "a", created_at: 2.days.ago)
    recent = AdminAction.create!(actor: users(:admin), action: "b", created_at: 1.hour.ago)
    assert_equal [ recent, old ], AdminAction.ordered.to_a
  end

  test "survives deletion of its actor" do
    entry = AdminAction.create!(actor: users(:member), action: "user_role_changed")
    users(:member).destroy!
    assert_nil entry.reload.actor_id
  end
end
