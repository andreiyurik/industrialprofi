require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  # ── Auth: the overview is admin-only ──

  test "show without auth redirects to sign-in" do
    get admin_root_path
    assert_redirected_to new_session_path
  end

  test "show as a member is not allowed" do
    sign_in_as users(:member)
    get admin_root_path
    assert_redirected_to root_path
  end

  test "show as an editor is not allowed" do
    sign_in_as users(:editor)
    get admin_root_path
    assert_redirected_to root_path
  end

  # ── Content ──

  test "show as admin renders the stats" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_response :success
    assert_match User.count.to_s, response.body
    assert_match users(:member).email_address, response.body  # recent signups
    assert_match I18n.t("admin.dashboard.signups_chart"), response.body
  end

  test "renders both the signups and completions charts" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_match I18n.t("admin.dashboard.signups_chart"), response.body
    assert_match I18n.t("admin.dashboard.completions_chart"), response.body
  end

  test "admin pages drop the public marketing footer" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_no_match "footer__inner", response.body
  end

  test "pending_review materials surface as a callout to the program" do
    paths(:draft_path).update!(status: "pending_review")

    sign_in_as users(:admin)
    get admin_root_path
    assert_match I18n.t("admin.dashboard.pending_review", count: 1), response.body
    assert_match admin_paths_path, response.body
  end

  test "no pending_review callout when nothing awaits publication" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_no_match I18n.t("admin.dashboard.open_program"), response.body
  end

  test "pending suggestions callout links to the moderation queue" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_match I18n.t("admin.dashboard.review_now"), response.body
  end

  test "the self-sufficiency compass counts published paths with a non-founder editor" do
    sign_in_as users(:admin)
    get admin_root_path
    # The fixture editor maintains electrician (published) and a draft;
    # welder has nobody — 1 of 2 published paths is founder-independent.
    assert_match I18n.t("admin.dashboard.paths_with_editors"), response.body
    assert_match I18n.t("admin.dashboard.paths_with_editors_count", covered: 1, total: 2), response.body
  end

  test "a dormant grant does not count toward the compass" do
    users(:editor).update!(role: :member)

    sign_in_as users(:admin)
    get admin_root_path
    assert_match I18n.t("admin.dashboard.paths_with_editors_count", covered: 0, total: 2), response.body
  end

  test "editorship candidates surface with a link to the user card" do
    member = users(:member)
    TrackRecord::TRUSTED_AT.times do
      member.lesson_suggestions.create!(lesson: lessons(:pteep), author_name: member.name,
        body_markdown: "Правка", status: "approved")
    end

    sign_in_as users(:admin)
    get admin_root_path
    assert_match I18n.t("admin.dashboard.candidates_title"), response.body
    assert_match member.name, response.body
    assert_match admin_user_path(member), response.body
  end

  test "no candidates block when nobody has earned a proposal" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_no_match I18n.t("admin.dashboard.candidates_title"), response.body
  end

  test "show embeds the vitals frame" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_match admin_dashboard_vitals_path, response.body
  end

  # ── Vitals: the disk/mail/jobs cards load in their own frame ──

  test "vitals requires admin" do
    sign_in_as users(:member)
    get admin_dashboard_vitals_path
    assert_redirected_to root_path
  end

  test "the disk-safety card renders in the vitals frame" do
    sign_in_as users(:admin)
    get admin_dashboard_vitals_path
    assert_response :success
    assert_match I18n.t("admin.dashboard.disk_free"), response.body
    assert_match "База данных", response.body
  end

  test "the mail-flow card renders in the vitals frame" do
    sign_in_as users(:admin)
    get admin_dashboard_vitals_path
    assert_match I18n.t("admin.dashboard.emails_week"), response.body
  end

  test "callout is hidden when the queue is empty" do
    LessonSuggestion.pending.update_all(status: "approved")
    sign_in_as users(:admin)
    get admin_root_path
    assert_no_match I18n.t("admin.dashboard.review_now"), response.body
  end

  test "a recent coauthor application surfaces as a dashboard callout to the filtered inbox" do
    Feedback.create!(user: users(:member), body: "Профессия: Пекарь",
                     page_url: Feedback::COAUTHOR_APPLICATION_PATH)
    sign_in_as users(:admin)
    get admin_root_path
    assert_match I18n.t("admin.dashboard.open_applications"), response.body
    assert_select "a[href=?]", admin_feedbacks_path(only: "coauthor")
  end
end
