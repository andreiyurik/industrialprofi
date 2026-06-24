module Admin::AdminActionsHelper
  # Renders one log entry as a localized human sentence. Reads the denormalized
  # `details` (role/section keys get localized; a path list is joined), so the
  # line is self-contained and never depends on the target row still existing.
  def admin_action_description(entry)
    details = entry.details.symbolize_keys
    options = details.dup

    options[:from] = t("admin.roles.#{details[:from]}") if details[:from].present?
    options[:to]   = t("admin.roles.#{details[:to]}")   if details[:to].present?
    if details[:section].present?
      options[:section] = t("admin.log.sections.#{details[:section]}", default: details[:section])
    end
    options[:paths] = Array(details[:paths]).join(", ") if details.key?(:paths)

    # An access change that left no professions reads as "access cleared".
    key = entry.action
    key = "user_access_cleared" if entry.action == "user_access_changed" && options[:paths].blank?

    t("admin.log.actions.#{key}", **options, default: entry.action)
  end
end
