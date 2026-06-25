require "test_helper"

class EditorshipTest < ActiveSupport::TestCase
  test "a user can't be granted the same profession twice" do
    dup = Editorship.new(user: users(:editor), path: paths(:electrician))
    assert_not dup.valid?, "the (user, path) grant is unique"
  end

  test "can_edit_path? is scoped to granted professions for editors" do
    editor = users(:editor)
    assert editor.can_edit_path?(paths(:electrician)), "granted"
    assert_not editor.can_edit_path?(paths(:welder)), "not granted"
  end

  test "admins can edit every profession without a grant" do
    admin = users(:admin)
    assert_empty admin.editorships
    assert admin.can_edit_path?(paths(:electrician))
    assert admin.can_edit_path?(paths(:welder))
  end

  test "Path.editable_by returns granted paths for an editor and all for an admin" do
    assert_equal [ paths(:electrician), paths(:draft_path) ].map(&:id).sort,
                 Path.editable_by(users(:editor)).pluck(:id).sort
    assert_equal Path.count, Path.editable_by(users(:admin)).count
  end

  test "destroying a path removes its grants" do
    assert_difference -> { Editorship.count }, -1 do
      paths(:electrician).destroy
    end
  end
end
