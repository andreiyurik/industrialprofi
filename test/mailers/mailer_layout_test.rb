require "test_helper"

# The shared brand layout every HTML mail renders through.
class MailerLayoutTest < ActionMailer::TestCase
  setup do
    @body = SignupsMailer.verification_code("novichok@example.com", "K7X2M9").html_part.body.to_s
  end

  # A relative asset path is a broken image in every mail client, and nothing
  # about the rendered mail looks wrong from inside the app.
  test "the logo is served from an absolute URL" do
    assert_match %r{<img src="https?://[^"]+/assets/logo-ethernet-[^"]+\.png"}, @body
  end

  # The seal is the only brand mark in the letter, so its alt is what a reader
  # with images off has left.
  test "the logo alt carries the brand name" do
    assert_match %r{<img[^>]+alt="#{I18n.t("site.name")}"}, @body
  end

  # Ink and background must travel together: a client that keeps the bgcolor
  # attribute but drops our styling would otherwise render black on black.
  test "ink colour ships inline alongside the black ground" do
    assert_match %r{bgcolor="#000000"}, @body
    assert_match %r{style="[^"]*color: #ebebeb}, @body
  end
end
