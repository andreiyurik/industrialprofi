require "test_helper"

class LessonsControllerTest < ActionDispatch::IntegrationTest
  test "show returns success for published lesson" do
    get lesson_path(lessons(:pteep))
    assert_response :success
    assert_match lessons(:pteep).title, response.body
  end

  test "show returns 404 for unknown slug" do
    get lesson_path(slug: "nonexistent")
    assert_response :not_found
  end

  test "show displays resources" do
    get lesson_path(lessons(:pteep))
    assert_match resources(:pteep_doc).title, response.body
  end

  test "sidebar shows the current course's contents" do
    get lesson_path(lessons(:gruppy_dopuska))
    assert_match courses(:el_basics).title, response.body  # sidebar header = course
    assert_match lessons(:pteep).title, response.body      # sibling lesson in same course
  end

  test "next link flows across course boundaries within the profession" do
    # gruppy_dopuska is the last lesson of el_basics; next is the first of el_pue.
    get lesson_path(lessons(:gruppy_dopuska))
    assert_match lesson_path(lessons(:zazemlenie)), response.body
  end

  test "show markdown format returns raw markdown" do
    get lesson_path(lessons(:pteep), format: :md)
    assert_response :success
    assert_match %r{text/markdown}, response.content_type
    assert_includes response.body, lessons(:pteep).title
    assert_includes response.body, lessons(:pteep).body
  end

  test "show renders markdown in html body" do
    get lesson_path(lessons(:pteep))
    assert_select "div.prose"
  end

  test "show renders the lesson toc with anchored body headings" do
    get lesson_path(lessons(:pteep))
    assert_select "aside.lesson-toc" do
      assert_select ".lesson-toc__link[href='#study']"
      # anchors are transliterated to ASCII (Turbo can't scroll to Cyrillic fragments)
      assert_select ".lesson-toc__link--sub[href='#poryadok-dopuska-k-rabotam']", text: "Порядок допуска к работам"
    end
    # the in-body heading itself carries the matching anchor
    assert_select "h2#poryadok-dopuska-k-rabotam"
  end

  test "practice lesson shows the journal CTA under the task for signed-in users" do
    get lesson_path(lessons(:praktika_shchitok))
    assert_select ".lesson-task-journal", false # signed out — no dead CTA

    sign_in_as users(:member)
    get lesson_path(lessons(:praktika_shchitok))
    assert_select ".lesson-task-journal"

    get lesson_path(lessons(:pteep)) # theory lesson — task, but no journal CTA
    assert_select ".lesson-task-journal", false
  end

  test "edit-lesson button only shows to a user who can edit this profession" do
    # signed out: no button
    get lesson_path(lessons(:pteep))
    assert_select "a.lesson__edit", false

    # a plain member: no button
    sign_in_as users(:member)
    get lesson_path(lessons(:pteep))
    assert_select "a.lesson__edit", false
    sign_out

    # an editor sees it on a profession they were granted, linking to the editor
    sign_in_as users(:editor)
    get lesson_path(lessons(:pteep)) # electrician — granted
    assert_select "a.lesson__edit[href=?]", edit_admin_lesson_path(lessons(:pteep))
    # and the "edit links" button by the resources block jumps to the link editor
    assert_select "a.resource-block__edit[href=?]",
      edit_admin_lesson_path(lessons(:pteep), anchor: "resources-editor")
    # but NOT on a profession they were not granted (welder)
    get lesson_path(lessons(:svarka_intro))
    assert_select "a.lesson__edit", false
    sign_out

    # an admin sees it everywhere
    sign_in_as users(:admin)
    get lesson_path(lessons(:svarka_intro))
    assert_select "a.lesson__edit[href=?]", edit_admin_lesson_path(lessons(:svarka_intro))
  end

  test "lesson colophon: none on a pristine lesson, quiet credit + history link once revised" do
    get lesson_path(lessons(:pteep))
    assert_select "footer.lesson-colophon", false # never edited → no colophon

    lessons(:pteep).revise!(section: "body", html: "<p>точнее</p>",
                            editor_name: "Наталья Орлова", edit_reason: "уточнила", source: "suggestion")
    get lesson_path(lessons(:pteep))
    assert_select "footer.lesson-colophon" do
      assert_select "a[href=?]", lesson_revisions_path(lessons(:pteep)) # history on its own page
      assert_select ".avatar", false # quiet byline — no avatar, no badges
    end
    assert_match "Наталья Орлова", response.body
  end

  test "reading mode cookie renders the stripped layout server-side" do
    get lesson_path(lessons(:pteep))
    assert_select "div.lesson-layout--reading", false

    cookies[:reading_mode] = "1"
    get lesson_path(lessons(:pteep))
    assert_select "div.lesson-layout--reading"
  end
end
