# Preview all emails at http://localhost:3000/rails/mailers
class FeedbackMailerPreview < ActionMailer::Preview
  def new_message
    FeedbackMailer.new_message(Feedback.last)
  end
end
