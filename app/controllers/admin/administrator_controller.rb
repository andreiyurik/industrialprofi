module Admin
  # Base for the administrator-only corner of the admin namespace (people,
  # moderation log, dashboard) — re-tightens BaseController's editor-level gate.
  class AdministratorController < BaseController
    before_action :ensure_can_administer
  end
end
