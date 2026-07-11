require "test_helper"

class EditorWelcomesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = users(:editor)
    @editor.update!(editor_welcomed_at: nil)
  end

  # ── The letter shows until acknowledged ──

  test "a freshly promoted editor sees the founder's letter on any page" do
    sign_in_as @editor
    get dashboard_path
    assert_select ".welcome-letter .welcome-letter__signature"
    assert_select ".welcome-letter form[action=?]", editor_welcome_path
  end

  test "the letter persists across pages until acknowledged" do
    sign_in_as @editor
    get paths_path
    assert_select ".welcome-letter"
  end

  test "members and administrators never see the editor letter" do
    sign_in_as users(:member)
    get dashboard_path
    assert_select ".welcome-letter", count: 0

    sign_in_as users(:admin)
    get dashboard_path
    assert_select ".welcome-letter", count: 0
  end

  test "an acknowledged editor is not greeted again" do
    @editor.update!(editor_welcomed_at: Time.current)
    sign_in_as @editor
    get dashboard_path
    assert_select ".welcome-letter", count: 0
  end

  # ── Acknowledging ──

  test "dismissing marks the welcome and returns to the same page" do
    sign_in_as @editor
    get paths_path
    delete editor_welcome_path, headers: { "HTTP_REFERER" => paths_url }

    assert_redirected_to paths_url
    assert @editor.reload.editor_welcomed_at.present?
  end

  test "the primary action acknowledges and lands on the review queue" do
    sign_in_as @editor
    delete editor_welcome_path(open_queue: 1)

    assert_redirected_to admin_lesson_suggestions_path
    assert @editor.reload.editor_welcomed_at.present?
  end

  test "requires authentication" do
    delete editor_welcome_path
    assert_redirected_to new_session_path
  end
end
