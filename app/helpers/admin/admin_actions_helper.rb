module Admin::AdminActionsHelper
  # Reads the denormalized `details` so the line is self-contained even if the target row no longer exists.
  def admin_action_description(entry)
    details = entry.details.symbolize_keys
    options = details.dup

    options[:from] = t("admin.roles.#{details[:from]}") if details[:from].present?
    options[:to]   = t("admin.roles.#{details[:to]}")   if details[:to].present?
    # Path/Course lifecycle entries carry raw statuses; localize them at render.
    %i[status from_status to_status].each do |slot|
      options[slot] = t("admin.log.statuses.#{details[slot]}", default: details[slot]) if details[slot].present?
    end
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
