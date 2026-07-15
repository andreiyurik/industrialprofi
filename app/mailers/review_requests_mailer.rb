class ReviewRequestsMailer < ApplicationMailer
  # An editor flipped a profession or course to "на проверке" and is waiting for
  # an administrator to publish. A rare administrative notice (no unsubscribe),
  # so a submission is never missed sitting on the dashboard.
  def submitted(record, submitter)
    @record = record
    @submitter = submitter
    @course = record.is_a?(Course)
    @kind = @course ? :course : :path
    @profession = @course ? record.path&.title : record.title
    @review_url = @course ? edit_admin_course_url(record) : edit_admin_path_url(record)

    recipients = User.administrator.pluck(:email_address)
    return if recipients.empty?

    mail to: recipients,
         subject: t("review_requests_mailer.submitted.subject.#{@kind}", title: record.title)
  end
end
