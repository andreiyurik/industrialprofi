# Preview all emails at http://localhost:3000/rails/mailers
class ReviewRequestsMailerPreview < ActionMailer::Preview
  def submitted
    ReviewRequestsMailer.submitted(Path.published.first, User.first)
  end
end
