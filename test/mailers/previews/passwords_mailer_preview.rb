# Preview all emails at http://localhost:3000/rails/mailers
class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    PasswordsMailer.reset(User.first)
  end
end
