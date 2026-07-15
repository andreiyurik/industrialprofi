require "test_helper"

class ReactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:published)
  end

  test "requires authentication" do
    post post_reaction_path(@post)
    assert_redirected_to new_session_path
  end

  test "create adds a reaction and re-renders the button via turbo stream" do
    sign_in_as users(:member)

    assert_difference -> { @post.reactions.count }, 1 do
      post post_reaction_path(@post), as: :turbo_stream
    end
    assert_response :success
    assert_match "reaction_post_#{@post.id}", response.body
  end

  test "create is idempotent" do
    sign_in_as users(:member)
    users(:member).reactions.create!(reactable: @post)

    assert_no_difference -> { Reaction.count } do
      post post_reaction_path(@post)
    end
  end

  test "destroy removes the reaction" do
    sign_in_as users(:member)
    users(:member).reactions.create!(reactable: @post)

    assert_difference -> { Reaction.count }, -1 do
      delete post_reaction_path(@post)
    end
  end

  test "cannot react to a draft post" do
    sign_in_as users(:member)

    assert_no_difference -> { Reaction.count } do
      post post_reaction_path(posts(:draft))
    end
    assert_response :not_found
  end
end
