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

  # Pack upload (.zip of the exported tree)

  test "uploading a pack shows the same dry-run preview" do
    assert_no_difference -> { Path.count } do
      post admin_imports_path, params: { archive: pack_upload }
    end
    assert_response :success
    assert_select ".import-plan"
    assert_match "Кровельщик", response.body
  end

  test "a broken archive re-renders the form with the pack error" do
    file = Tempfile.new([ "pack", ".zip" ])
    file.write("это не архив")
    file.rewind

    assert_no_difference -> { Path.count } do
      post admin_imports_path,
        params: { archive: Rack::Test::UploadedFile.new(file.path, "application/zip") }
    end
    assert_response :unprocessable_entity
    assert_match I18n.t("admin.imports.errors.not_a_zip"), response.body
  end

  private

  # A minimal pack: the exporter's tree for one profession, zipped.
  def pack_upload
    zip = Zip::OutputStream.write_buffer do |stream|
      { "krovelshchik/path.yml" => { "title" => "Кровельщик", "description" => "Профессия." }.to_yaml,
        "krovelshchik/01-kurs/course.yml" => { "slug" => "bazovyi-kurs-krovli", "title" => "Базовый курс кровли" }.to_yaml,
        "krovelshchik/01-kurs/01-section/section.yml" => { "title" => "Старт" }.to_yaml,
        "krovelshchik/01-kurs/01-section/vvedenie-v-krovlyu.md" => <<~MD
          ---
          title: "Введение в кровлю"
          ---
          Зачем нужна кровля.
          ---
          Текст урока.
        MD
      }.each do |name, content|
        stream.put_next_entry(name)
        stream.write(content)
      end
    end

    file = Tempfile.new([ "pack", ".zip" ])
    file.binmode
    file.write(zip.string)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "application/zip")
  end
end
