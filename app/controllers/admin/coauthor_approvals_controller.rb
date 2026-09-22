module Admin
  # One-gesture coauthor approval: promotes to editor, creates the draft profession,
  # grants editorship, and logs it. The trust call and final publish stay human.
  class CoauthorApprovalsController < AdministratorController
    def create
      feedback = Feedback.coauthor_applications.find(params[:feedback_id])
      applicant = feedback.user
      title = params[:profession_title].to_s.strip

      if applicant.nil? || title.blank?
        return redirect_to admin_feedbacks_path, alert: t("admin.coauthor_approve.incomplete")
      end

      # Idempotent: a double-submit lands on the already-made draft, not a second "Профессия-2".
      if (existing = applicant.editable_paths.find_by(title: title, status: "draft"))
        return redirect_to edit_admin_path_path(existing),
          notice: t("admin.coauthor_approve.already", profession: existing.title)
      end

      path = nil
      ActiveRecord::Base.transaction do
        path = Path.create!(title: title, author_id: applicant.id, status: "draft",
                            position: (Path.maximum(:position) || 0) + 1)
        applicant.editorships.create!(path: path)
        applicant.promote_to_editor_if_granted!
        record_admin_action("coauthor_approved", target: applicant,
          subject: applicant.name, profession: path.title)
        feedback.update!(read_at: Time.current) if feedback.read_at.nil?
      end

      applicant.notify_editorship_grant([ path ])
      redirect_to edit_admin_path_path(path),
        notice: t("admin.coauthor_approve.approved", name: applicant.name, profession: path.title)
    end
  end
end
