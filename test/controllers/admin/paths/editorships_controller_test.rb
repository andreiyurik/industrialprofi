require "test_helper"

class Admin::Paths::EditorshipsControllerTest < ActionDispatch::IntegrationTest
  test "admin grants a seat, promoting a member to editor in the same stroke" do
    sign_in_as users(:admin)
    member = users(:member)

    assert_difference -> { AdminAction.where(action: "user_role_changed").count } do
      assert_enqueued_email_with EditorshipsMailer, :granted, args: [ member, [ paths(:welder) ] ] do
        post admin_path_editorships_path(paths(:welder)), params: { user_id: member.id }
      end
    end

    assert_redirected_to admin_path_path(paths(:welder))
    member.reload
    assert member.editor?
    assert_equal [ paths(:welder).id ], member.editable_path_ids
  end

  test "admin grants an additional seat to an already-active editor, no role change logged" do
    sign_in_as users(:admin)
    editor = users(:editor)

    assert_no_difference -> { AdminAction.where(action: "user_role_changed").count } do
      assert_enqueued_email_with EditorshipsMailer, :granted, args: [ editor, [ paths(:welder) ] ] do
        post admin_path_editorships_path(paths(:welder)), params: { user_id: editor.id }
      end
    end

    assert_includes editor.reload.editable_path_ids, paths(:welder).id
  end

  test "admin revokes a seat without demoting the editor" do
    sign_in_as users(:admin)
    editor = users(:editor)
    editorship = editorships(:editor_electrician)

    assert_no_enqueued_emails do
      delete admin_path_editorship_path(paths(:electrician), editorship)
    end

    assert_redirected_to admin_path_path(paths(:electrician))
    assert editor.reload.editor?
    assert_not_includes editor.editable_path_ids, paths(:electrician).id
  end

  test "an editor cannot grant or revoke seats" do
    sign_in_as users(:editor)

    post admin_path_editorships_path(paths(:electrician)), params: { user_id: users(:member).id }
    assert_redirected_to root_path

    delete admin_path_editorship_path(paths(:electrician), editorships(:editor_electrician))
    assert_redirected_to root_path
  end

  # ── Turbo Stream (in-place team panel update, no full-page reload) ──

  test "granting via turbo_stream replaces the team panel and updates the flash in place" do
    sign_in_as users(:admin)
    member = users(:member)

    post admin_path_editorships_path(paths(:welder)), params: { user_id: member.id }, as: :turbo_stream

    assert_response :success
    assert_match %r{<turbo-stream action="replace" target="path_team">}, response.body
    assert_match member.name, response.body
    assert_match %r{<turbo-stream action="update" target="flash">}, response.body
  end

  test "revoking via turbo_stream replaces the team panel and updates the flash in place" do
    sign_in_as users(:admin)
    editor = users(:editor)
    editorship = editorships(:editor_electrician)

    delete admin_path_editorship_path(paths(:electrician), editorship), as: :turbo_stream

    assert_response :success
    assert_match %r{<turbo-stream action="replace" target="path_team">}, response.body
    # electrician's only editor was just revoked — the panel now reports the honest empty state.
    assert_match I18n.t("admin.builder.team_empty"), response.body
    assert_match %r{<turbo-stream action="update" target="flash">}, response.body
  end
end
