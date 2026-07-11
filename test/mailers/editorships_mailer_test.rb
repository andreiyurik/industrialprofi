require "test_helper"

class EditorshipsMailerTest < ActionMailer::TestCase
  test "granted names the profession and points at the review queue and guide" do
    email = EditorshipsMailer.granted(users(:member), [ paths(:electrician) ])

    assert_equal [ users(:member).email_address ], email.to
    assert_includes email.subject, paths(:electrician).title
    assert_match paths(:electrician).title, email.html_part.body.to_s
    assert_match "/admin/lesson_suggestions", email.html_part.body.to_s
    assert_match "/guide", email.html_part.body.to_s
    assert_match "/guide", email.text_part.body.to_s
  end

  test "granted several professions lists them all with a counted subject" do
    email = EditorshipsMailer.granted(users(:member), [ paths(:electrician), paths(:welder) ])

    assert_includes email.subject, "2"
    assert_match paths(:electrician).title, email.html_part.body.to_s
    assert_match paths(:welder).title, email.html_part.body.to_s
  end
end
