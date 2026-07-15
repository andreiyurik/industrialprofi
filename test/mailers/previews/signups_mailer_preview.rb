# Preview all emails at http://localhost:3000/rails/mailers
class SignupsMailerPreview < ActionMailer::Preview
  def verification_code
    SignupsMailer.verification_code("novichok@example.com", "K7X2M9")
  end
end
