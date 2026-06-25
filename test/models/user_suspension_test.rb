require "test_helper"

class UserSuspensionTest < ActiveSupport::TestCase
  test "active and suspended scopes split on suspended_at" do
    member = users(:member)
    assert_includes User.active, member
    assert_not_includes User.suspended, member

    member.suspend!
    assert_includes User.suspended, member
    assert_not_includes User.active, member
  end

  test "suspend! revokes every session and blocks the account" do
    member = users(:member)
    member.sessions.create!
    member.sessions.create!

    assert_difference -> { Session.where(user: member).count }, -2 do
      member.suspend!
    end
    assert member.suspended?
    assert_not_nil member.suspended_at
  end

  test "reinstate! lifts the ban" do
    member = users(:member)
    member.suspend!
    member.reinstate!
    assert_not member.suspended?
    assert_nil member.suspended_at
  end
end
