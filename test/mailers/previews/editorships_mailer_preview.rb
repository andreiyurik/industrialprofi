# Preview all emails at http://localhost:3000/rails/mailers
class EditorshipsMailerPreview < ActionMailer::Preview
  def granted
    EditorshipsMailer.granted(User.first, Path.published.first(2))
  end
end
