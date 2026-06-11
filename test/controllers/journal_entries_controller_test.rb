require "test_helper"

class JournalEntriesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get journal_entries_path
    assert_redirected_to new_session_path
  end

  test "index shows only own entries" do
    users(:member).journal_entries.create!(body: "Моя запись про щиток")
    users(:admin).journal_entries.create!(body: "Чужая запись про сварку")

    sign_in_as users(:member)
    get journal_entries_path
    assert_response :success
    assert_match "Моя запись про щиток", response.body
    assert_no_match(/Чужая запись про сварку/, response.body)
  end

  test "create with photo and lesson link" do
    sign_in_as users(:member)

    assert_difference -> { users(:member).journal_entries.count }, 1 do
      post journal_entries_path, params: { journal_entry: {
        title: "Сборка щитка",
        body: "<p>Собрал по однолинейной схеме</p>",
        lesson_id: lessons(:praktika_shchitok).id,
        photos: [ fixture_file_upload("photo.png", "image/png") ]
      } }
    end
    assert_redirected_to journal_entries_path

    entry = users(:member).journal_entries.ordered.first
    assert entry.photos.attached?
    assert_equal lessons(:praktika_shchitok), entry.lesson
  end

  test "create without body re-renders" do
    sign_in_as users(:member)

    assert_no_difference -> { JournalEntry.count } do
      post journal_entries_path, params: { journal_entry: { title: "Пусто", body: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "cannot edit another user's entry" do
    entry = users(:admin).journal_entries.create!(body: "Чужая запись")

    sign_in_as users(:member)
    get edit_journal_entry_path(entry)
    assert_response :not_found
  end

  test "destroy removes the entry" do
    entry = users(:member).journal_entries.create!(body: "Удаляемая запись")

    sign_in_as users(:member)
    assert_difference -> { JournalEntry.count }, -1 do
      delete journal_entry_path(entry)
    end
    assert_redirected_to journal_entries_path
  end
end
