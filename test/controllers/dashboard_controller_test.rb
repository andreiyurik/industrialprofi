require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "signed-in user landing on root is sent to the dashboard" do
    sign_in_as users(:member)
    get root_path
    assert_redirected_to dashboard_path
  end

  test "catalog stays reachable at /paths when signed in" do
    sign_in_as users(:member)
    get paths_path
    assert_response :success
  end

  # ── Header account menu: the quiet role mark + the editors' entry point ──

  test "an editor sees their role badge and the Редактура menu item" do
    sign_in_as users(:editor)
    get dashboard_path
    assert_select ".account-menu__role", text: I18n.t("admin.roles.editor")
    assert_match I18n.t("nav.editing"), response.body
    assert_no_match I18n.t("nav.admin"), response.body
  end

  test "a member gets no role badge" do
    sign_in_as users(:member)
    get dashboard_path
    assert_select ".account-menu__role", count: 0
  end

  test "an administrator's menu item stays Admin" do
    sign_in_as users(:admin)
    get dashboard_path
    assert_select ".account-menu__role", text: I18n.t("admin.roles.administrator")
    assert_match I18n.t("nav.admin"), response.body
  end

  test "shows empty state without completions" do
    sign_in_as users(:member)
    get dashboard_path
    assert_response :success
    assert_match I18n.t("dashboard.browse_paths"), response.body
  end

  test "lists bookmarked tasks with remove buttons" do
    users(:member).lesson_bookmarks.create!(lesson: lessons(:praktika_shchitok))
    sign_in_as users(:member)

    get dashboard_path
    assert_select "#dashboard_bookmarks" do
      assert_select ".dashboard-bookmark", 1
      assert_select ".dashboard-bookmark__remove"
    end
    assert_match lessons(:praktika_shchitok).title, response.body
  end

  test "hides the bookmarks section when there are none" do
    sign_in_as users(:member)
    get dashboard_path
    assert_select "#dashboard_bookmarks", false
  end

  test "shows started path with continue link to next lesson" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get dashboard_path
    assert_response :success
    assert_match paths(:electrician).title, response.body
    assert_match lesson_path(lessons(:gruppy_dopuska)), response.body
  end

  test "focus path is the hero; other started paths are listed quietly" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep), created_at: 2.days.ago)
    users(:member).lesson_completions.create!(lesson: lessons(:svarka_intro), created_at: 1.hour.ago)

    sign_in_as users(:member)
    get dashboard_path
    assert_match "dashboard-hero", response.body
    assert_match I18n.t("dashboard.focus_title"), response.body
    assert_match I18n.t("dashboard.other_paths"), response.body
  end

  test "does not suggest new paths to a learner who already started one" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get dashboard_path
    assert_no_match(/#{I18n.t("dashboard.suggested")}/, response.body)
  end

  test "shows activity heatmap with the explainer once a path is started" do
    sign_in_as users(:member)
    get dashboard_path
    assert_no_match(/heatmap__grid/, response.body)

    users(:member).lesson_completions.create!(lesson: lessons(:pteep))
    get dashboard_path
    assert_match "heatmap__grid", response.body
    assert_match "heatmap__cell--l1", response.body
    assert_match I18n.t("dashboard.heatmap_hint"), response.body
  end

  test "shows an empty heatmap to a returning learner, not a missing section" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep), created_at: 20.weeks.ago)

    sign_in_as users(:member)
    get dashboard_path
    assert_match "heatmap__grid", response.body
    assert_match I18n.t("dashboard.heatmap_summary", count: 0), response.body
  end

  test "header shows the account menu for signed-in users" do
    sign_in_as users(:member)
    get dashboard_path
    assert_select "button.account-menu-button", text: /#{users(:member).name}/
    assert_select "div#account-menu[popover]"
    assert_select "#account-menu form[action=?]", session_path
  end

  test "shows per-course progress rows for the focus path" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get dashboard_path
    assert_match "dashboard-course", response.body
    assert_match I18n.t("dashboard.courses_title"), response.body
    assert_match courses(:el_basics).title, response.body
  end

  test "lists my suggestions with the reviewer's comment and marks decisions seen" do
    users(:member).lesson_suggestions.create!(
      lesson: lessons(:pteep), section: "body", author_name: "Иван",
      body_markdown: "Правка", status: "rejected", reviewed_at: 1.hour.ago,
      reviewer_comment: "Сверьте с ПУЭ."
    )

    sign_in_as users(:member)
    get dashboard_path

    assert_select "#dashboard_suggestions" do
      assert_select ".dashboard-suggestion", 1
      assert_select ".notify-dot", minimum: 1
    end
    assert_match "Сверьте с ПУЭ.", response.body
    assert users(:member).reload.suggestions_seen_at.present?

    # Second visit: the decision was seen, the fresh marker is gone.
    get dashboard_path
    assert_select "#dashboard_suggestions .notify-dot", 0
  end

  test "hides the suggestions section for users who never suggested" do
    sign_in_as users(:member)
    get dashboard_path
    assert_select "#dashboard_suggestions", false
    assert_nil users(:member).reload.suggestions_seen_at
  end

  test "header shows the unseen-decision dot until the dashboard is visited" do
    users(:member).lesson_suggestions.create!(
      lesson: lessons(:pteep), section: "body", author_name: "Иван",
      body_markdown: "Правка", status: "approved", reviewed_at: 1.hour.ago
    )

    sign_in_as users(:member)
    get paths_path
    assert_select ".account-menu-button .notify-dot", 1

    get dashboard_path
    get paths_path
    assert_select ".account-menu-button .notify-dot", 0
  end
end
