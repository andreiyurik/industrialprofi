# Preview all emails at http://localhost:3000/rails/mailers
class AccountMailerPreview < ActionMailer::Preview
  def email_change_code
    AccountMailer.email_change_code("novyi@example.com", "P4Q8R1")
  end
end
