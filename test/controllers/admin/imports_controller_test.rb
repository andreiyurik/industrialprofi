require "test_helper"

class Admin::ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  DOC = <<~YAML.freeze
    path:
      title: "Кровельщик"
      description: "Профессия."
    courses:
      - title: "Базовый курс кровли"
        sections:
          - title: "Старт"
            lessons:
              - title: "Введение в кровлю"
  YAML

  test "a member cannot access import" do
    sign_out
    sign_in_as users(:member)
    get new_admin_import_path
    assert_redirected_to root_path
  end

  test "new renders" do
    get new_admin_import_path
    assert_response :success
  end

  test "posting without confirm shows the dry-run preview and writes nothing" do
    assert_no_difference -> { Path.count } do
      post admin_imports_path, params: { yaml: DOC }
    end
    assert_response :success
    assert_select ".import-plan"
  end

  test "confirming imports as draft and redirects to the new path's edit page" do
    assert_difference -> { Path.count }, 1 do
      post admin_imports_path, params: { yaml: DOC, confirm: "1" }
    end
    path = Path.find_by!(title: "Кровельщик")
    assert_equal "draft", path.status
    assert_equal "ai", path.origin
    assert_redirected_to edit_admin_path_path(path)
  end

  test "invalid yaml re-renders the form" do
    assert_no_difference -> { Path.count } do
      post admin_imports_path, params: { yaml: "path: [broken", confirm: "1" }
    end
    assert_response :unprocessable_entity
  end
end
