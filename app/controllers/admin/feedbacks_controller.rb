module Admin
  # Messages to the founder — administrator-only (unlike content sections,
  # these are personal mail, not editorial work).
  class FeedbacksController < BaseController
    before_action :ensure_can_administer

    PER_PAGE = 50

    def index
      @page = [ params[:page].to_i, 1 ].max
      # The dashboard "заявки соавторов" callout links here filtered, so the
      # founder triages applications without scrolling the whole inbox.
      @coauthor_only = params[:only] == "coauthor"
      scope = Feedback.includes(:user).newest_first
      scope = scope.coauthor_applications if @coauthor_only

      # Fetch one extra to learn if a next page exists without a second query.
      records = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
      @has_more = records.size > PER_PAGE
      @feedbacks = records.first(PER_PAGE)

      # Opening the inbox is reading it — clears the nav badge. A filtered view
      # only clears what it actually shows, so unseen general messages stay unread.
      (@coauthor_only ? Feedback.coauthor_applications : Feedback).unread.update_all(read_at: Time.current)
    end

    # The one-gesture approval of a coauthor application: promote the applicant to
    # editor (if needed), create the draft profession under their name, grant them
    # the editorship, and log it — the mechanical grant the founder used to do by
    # hand across two screens. The trust call (reading the application) and the
    # final publish stay human; this only removes the busywork between them.
    def approve_coauthor
      feedback = Feedback.coauthor_applications.find(params[:id])
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
        applicant.update!(role: :editor) if applicant.member?
        applicant.editorships.create!(path: path)
        record_admin_action("coauthor_approved", target: applicant,
          subject: applicant.name, profession: path.title)
        feedback.update!(read_at: Time.current) if feedback.read_at.nil?
      end

      EditorshipsMailer.granted(applicant, [ path ]).deliver_later
      redirect_to edit_admin_path_path(path),
        notice: t("admin.coauthor_approve.approved", name: applicant.name, profession: path.title)
    end
  end
end
