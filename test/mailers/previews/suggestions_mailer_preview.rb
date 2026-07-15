# Preview all emails at http://localhost:3000/rails/mailers
class SuggestionsMailerPreview < ActionMailer::Preview
  def outcome_approved
    SuggestionsMailer.outcome(suggestion(status: "approved"))
  end

  def outcome_rejected
    SuggestionsMailer.outcome(suggestion(
      status: "rejected", reviewer_comment: "Формулировка расходится с ПУЭ 1.7.62 — уточните, пожалуйста."
    ))
  end

  def review_digest
    SuggestionsMailer.review_digest(User.editor.first || User.administrator.first)
  end

  private

  # Unsaved: a preview must never write to the database.
  def suggestion(attributes)
    LessonSuggestion.new({
      user: User.first, lesson: Lesson.first, section: "body",
      author_name: User.first.name, body_markdown: "Уточнение", reviewed_at: Time.current
    }.merge(attributes))
  end
end
