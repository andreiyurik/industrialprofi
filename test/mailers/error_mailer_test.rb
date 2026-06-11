require "test_helper"

class ErrorMailerTest < ActionMailer::TestCase
  test "alert goes to administrators with the error details" do
    email = ErrorMailer.alert(
      error_class: "RuntimeError",
      message: "boom",
      backtrace: [ "app/models/user.rb:1:in `explode'" ],
      severity: "error",
      source: "application.action_dispatch",
      context: "{}"
    )

    assert_equal [ users(:admin).email_address ], email.to
    assert_match "RuntimeError", email.subject
    assert_match "boom", email.body.to_s
    assert_match "explode", email.body.to_s
  end
end
