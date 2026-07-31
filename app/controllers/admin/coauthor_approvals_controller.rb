module Admin
  # The one-gesture approval of a coauthor application: promote the applicant to
  # editor (if needed), create the draft profession under their name, grant them
  # the editorship, and log it — the mechanical grant the founder used to do by
  # hand across two screens. The trust call (reading the application) and the
  # final publish stay human; this only removes the busywork between them.
  class CoauthorApprovalsController < AdministratorController
    def create
      feedback = Feedback.coauthor_applications.find(params[:feedback_id])
      applicant = feedback.user
      title = params[:profession_title].to_s.strip

      if applicant.nil? || title.blank?
        return redirect_to admin_feedbacks_path, alert: t("admin.coauthor_approve.incomplete")
      end

      # Idempotency: a double-submit lands back on the draft it already made
      # rather than spawning a second "Профессия-2".
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
