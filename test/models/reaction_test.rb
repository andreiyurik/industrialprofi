require "test_helper"

class ReactionTest < ActiveSupport::TestCase
  test "a user can react to a post only once" do
    user = users(:member)
    post = posts(:published)
    user.reactions.create!(reactable: post)

    dup = user.reactions.build(reactable: post)
    assert_not dup.valid?
  end

  test "counter_cache tracks reactions on a post" do
    post = posts(:published)
    assert_equal 0, post.reactions_count

    users(:member).reactions.create!(reactable: post)
    users(:admin).reactions.create!(reactable: post)
    assert_equal 2, post.reload.reactions_count

    post.reactions.first.destroy
    assert_equal 1, post.reload.reactions_count
  end

  test "reacted_by? reflects the user's reaction" do
    post = posts(:published)
    assert_not post.reacted_by?(users(:member))
    users(:member).reactions.create!(reactable: post)
    assert post.reacted_by?(users(:member))
    assert_not post.reacted_by?(nil)
  end
end
