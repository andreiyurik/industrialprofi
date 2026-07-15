# Preview all emails at http://localhost:3000/rails/mailers
class RemindersMailerPreview < ActionMailer::Preview
  def continue_learning
    RemindersMailer.continue_learning(User.joins(:lesson_completions).first)
  end
end
