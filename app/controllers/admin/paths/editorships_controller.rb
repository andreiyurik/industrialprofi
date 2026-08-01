module Admin
  module Paths
    # Grant/revoke a direct-edit seat on one profession, from the profession's
    # own team panel (see Admin::PathsController#show). Same effect as the
    # per-user picker in Admin::UsersController#update_access, just entered
    # from the other side — admin-only, same promotion/notification rules.
    class EditorshipsController < Admin::AdministratorController
      before_action :set_path

      def create
        user = User.active.find(params[:user_id])
        promoted = false

        @path.transaction do
          user.editorships.find_or_create_by!(path: @path)
          promoted = user.promote_to_editor_if_granted!
          record_admin_action("user_role_changed", target: user,
            subject: user.name, from: "member", to: user.role) if promoted
          record_admin_action("user_access_changed", target: user,
            subject: user.name, paths: user.editable_paths.reload.map(&:title))
        end
        user.notify_editorship_grant([ @path ])

        notice_key = promoted ? "admin.builder.team_added_promoted" : "admin.builder.team_added"
        respond(t(notice_key, name: user.name))
      end

      def destroy
        editorship = @path.editorships.find(params[:id])
        user = editorship.user

        @path.transaction do
          editorship.destroy!
          record_admin_action("user_access_changed", target: user,
            subject: user.name, paths: user.editable_paths.reload.map(&:title))
        end

        respond(t("admin.builder.team_removed", name: user.name))
      end

      private
        def set_path
          @path = Path.find_by!(slug: params[:path_slug])
        end

        # Turbo-replaces just the team panel (no full-page reload, no lost
        # scroll position on a long curriculum tree) — the HTML fallback still
        # redirects for no-JS/direct-link requests.
        def respond(notice)
          @editorships = @path.editorships.includes(:user).joins(:user).merge(User.order(:name))
          @editorship_candidates = Editorship.candidates_for(@path)

          respond_to do |format|
            format.turbo_stream { @notice = notice }
            format.html { redirect_to admin_path_path(@path), notice: notice }
          end
        end
    end
  end
end
