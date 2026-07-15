require "test_helper"

module Admin
  class PostsControllerTest < ActionDispatch::IntegrationTest
    test "members cannot reach news admin" do
      sign_in_as users(:member)
      get admin_posts_path
      assert_redirected_to root_path
    end

    test "editors cannot reach news admin (admin-only)" do
      sign_in_as users(:editor)
      get admin_posts_path
      assert_redirected_to root_path
    end

    test "admin lists posts" do
      sign_in_as users(:admin)
      get admin_posts_path
      assert_response :success
    end

    test "admin creates a post and publishing stamps the date" do
      sign_in_as users(:admin)

      assert_difference -> { Post.count }, 1 do
        post admin_posts_path, params: { post: { title: "Новая новость", status: "published" } }
      end
      created = Post.order(:created_at).last
      assert created.published_at.present?
      assert_redirected_to edit_admin_post_path(created)
    end

    test "admin updates a post" do
      sign_in_as users(:admin)
      patch admin_post_path(posts(:draft)), params: { post: { title: "Обновлённый заголовок" } }
      assert_equal "Обновлённый заголовок", posts(:draft).reload.title
    end

    test "admin destroys a post" do
      sign_in_as users(:admin)
      assert_difference -> { Post.count }, -1 do
        delete admin_post_path(posts(:draft))
      end
      assert_redirected_to admin_posts_path
    end
  end
end
