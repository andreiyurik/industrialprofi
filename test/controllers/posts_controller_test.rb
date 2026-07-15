require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "index lists published posts and is public" do
    get posts_path
    assert_response :success
    assert_select "a", text: /Первая новость платформы/
    assert_no_match posts(:draft).title, response.body
  end

  test "show renders a published post" do
    get post_path(posts(:published))
    assert_response :success
    assert_select "h1", text: posts(:published).title
  end

  test "show 404s on a draft post" do
    get post_path(posts(:draft))
    assert_response :not_found
  end
end
