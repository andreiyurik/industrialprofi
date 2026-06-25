require "test_helper"

class Admin::PathsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "index without auth redirects to sign-in" do
    sign_out
    get admin_paths_path
    assert_redirected_to new_session_path
  end

  test "index with auth returns success" do
    get admin_paths_path
    assert_response :success
    assert_match paths(:electrician).title, response.body
  end

  test "edit with auth returns success" do
    get edit_admin_path_path(paths(:electrician))
    assert_response :success
  end

  # ── Builder (show) ──

  test "show renders the builder tree with the profession's courses and lessons" do
    get admin_path_path(paths(:electrician))
    assert_response :success
    assert_select ".builder"
    assert_match courses(:el_basics).title, response.body
    assert_match lessons(:pteep).title, response.body
  end

  test "an editor cannot open the builder for an ungranted profession" do
    sign_out
    sign_in_as users(:editor)
    get admin_path_path(paths(:welder))
    assert_response :not_found
  end

  test "update with valid data redirects" do
    patch admin_path_path(paths(:electrician)),
      params: { path: { description: "New description" } }
    assert_redirected_to edit_admin_path_path(paths(:electrician))
    assert_equal "New description", paths(:electrician).reload.description
  end

  test "update with invalid data re-renders edit" do
    patch admin_path_path(paths(:electrician)),
      params: { path: { title: "" } }
    assert_response :unprocessable_entity
  end

  # ── Create ──

  test "new renders for admin" do
    get new_admin_path_path
    assert_response :success
  end

  test "create as admin makes a path owned by the author, slug auto-generated" do
    assert_difference -> { Path.count }, 1 do
      post admin_paths_path, params: { path: { title: "Сантехник", status: "published" } }
    end
    path = Path.find_by!(title: "Сантехник")
    assert_redirected_to edit_admin_path_path(path)
    assert_equal "published", path.status
    assert_equal users(:admin).id, path.author_id
    assert_equal "human", path.origin
    assert_equal "santehnik", path.slug
    assert path.position.positive?
  end

  test "an editor cannot publish a new path — it lands as draft" do
    sign_out
    sign_in_as users(:editor)
    post admin_paths_path, params: { path: { title: "Маляр", status: "published" } }
    path = Path.find_by!(title: "Маляр")
    assert_equal "draft", path.status
    assert_equal users(:editor).id, path.author_id
  end

  test "an editor can submit a new path for review" do
    sign_out
    sign_in_as users(:editor)
    post admin_paths_path, params: { path: { title: "Кровельщик", status: "pending_review" } }
    assert_equal "pending_review", Path.find_by!(title: "Кровельщик").status
  end

  test "an editor cannot publish a draft via update" do
    sign_out
    sign_in_as users(:editor)
    patch admin_path_path(paths(:draft_path)), params: { path: { status: "published" } }
    assert_equal "draft", paths(:draft_path).reload.status
  end

  test "an editor cannot change an already-published path's status" do
    sign_out
    sign_in_as users(:editor)
    patch admin_path_path(paths(:electrician)), params: { path: { status: "draft" } }
    assert_equal "published", paths(:electrician).reload.status
  end

  test "an admin can publish a draft via update" do
    patch admin_path_path(paths(:draft_path)), params: { path: { status: "published" } }
    assert_equal "published", paths(:draft_path).reload.status
  end

  # ── Per-profession access (editorships) ──

  test "an editor sees only the professions granted to them" do
    sign_out
    sign_in_as users(:editor)
    get admin_paths_path
    assert_match paths(:electrician).title, response.body
    assert_no_match(/#{paths(:welder).title}/, response.body)
  end

  test "an editor cannot open a profession they weren't granted" do
    sign_out
    sign_in_as users(:editor)
    get edit_admin_path_path(paths(:welder))
    assert_redirected_to admin_lessons_path
  end

  test "an editor cannot update a profession they weren't granted" do
    sign_out
    sign_in_as users(:editor)
    patch admin_path_path(paths(:welder)), params: { path: { description: "Взлом" } }
    assert_redirected_to admin_lessons_path
    assert_not_equal "Взлом", paths(:welder).reload.description
  end

  test "creating a profession grants the editor edit access to it" do
    sign_out
    sign_in_as users(:editor)
    post admin_paths_path, params: { path: { title: "Плиточник" } }
    path = Path.find_by!(title: "Плиточник")
    assert users(:editor).can_edit_path?(path), "the creator can edit what they made"
  end

  # ── Slug lock (SEO) ──

  test "the slug of a published path cannot be changed, other fields still save" do
    original = paths(:electrician).slug
    patch admin_path_path(paths(:electrician)),
      params: { path: { slug: "vzlomannyy", description: "Обновлённое описание" } }
    paths(:electrician).reload
    assert_equal original, paths(:electrician).slug
    assert_equal "Обновлённое описание", paths(:electrician).description
  end

  test "the slug of a draft path can be changed" do
    patch admin_path_path(paths(:draft_path)), params: { path: { slug: "novyy-chernovik" } }
    assert_equal "novyy-chernovik", paths(:draft_path).reload.slug
  end
end
