require "application_system_test_case"

# Lexxy is imported on demand (application.js), so the editor's configuration
# now has to win a race it used to be handed: Lexxy defines its custom elements
# from a setTimeout(0), and our configure() runs off the dynamic import. Lose
# that race and the editor still appears — just with the stock toolbar. So this
# reads the toolbar Lexxy built from our config, not the element.
class LessonEditorTest < ApplicationSystemTestCase
  test "the editor loads on demand and keeps our toolbar configuration" do
    sign_in_as users(:admin)
    visit edit_admin_lesson_path(lessons(:pteep))

    assert_selector "lexxy-editor"

    # h1 is the page title's, so the editor offers h2/h3 only. The buttons live
    # in a closed dropdown panel, hence visible: :all.
    assert_selector "button.lexxy-heading-button[data-heading='h2']", visible: :all
    assert_no_selector "button.lexxy-heading-button[data-heading='h1']", visible: :all

    # Colour is a badge mechanic here, never decorative prose.
    assert_no_selector "button.lexxy-highlight-button", visible: :all
  end

  test "a reader page never downloads the editor" do
    visit lesson_path(lessons(:pteep))

    assert_selector ".lesson-layout .lesson"
    # Lexxy bundles Prism and sets it on window — its absence is the proof.
    assert_equal "undefined", evaluate_script("typeof window.Prism")
  end

  # The other half of the on-demand rule: rendered rich text carries
  # <pre data-language>, and colouring it is the one thing a READER still needs
  # Lexxy for. Nothing has rich text yet, so this is the only place that would
  # notice the trigger going stale.
  #
  # A different lesson from the test above on purpose: a lesson page is
  # deliberately cacheable for anonymous readers, so sharing a URL let the
  # browser answer that test from this one's cached response — Prism loaded,
  # and it failed on whichever order the seed picked.
  test "saved rich text still gets its code coloured" do
    lessons(:zazemlenie).update!(rich_body: <<~HTML)
      <p>Пример.</p><pre data-language="st">IF ready THEN done := TRUE; END_IF</pre>
    HTML

    visit lesson_path(lessons(:zazemlenie))

    assert_selector "pre[data-language='st'][data-highlighted='true'] .token.keyword", text: "IF"
  end
end
