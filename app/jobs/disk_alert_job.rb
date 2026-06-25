class DiskAlertJob < ApplicationJob
  queue_as :default

  THRESHOLD_PERCENT = 80
  THROTTLE_KEY = "disk_alert_sent"
  THROTTLE_TTL = 24.hours

  def perform
    row = `df -k /rails/storage 2>/dev/null`.split("\n").last&.split
    return unless row&.size == 6

    used_percent = row[4].to_i          # "83%" → 83
    available_gb = (row[3].to_i / 1_048_576.0).round(1)  # KB → GB

    return if used_percent < THRESHOLD_PERCENT
    return unless first_alert_today?

    ErrorMailer.alert(
      error_class: "DiskSpaceWarning",
      message: "Диск заполнен на #{used_percent}%, свободно #{available_gb} ГБ на /rails/storage",
      backtrace: [],
      severity: "warning",
      source: "DiskAlertJob",
      context: row.inspect
    ).deliver_later
  end

  private
    def first_alert_today?
      Rails.cache.write(THROTTLE_KEY, true, unless_exist: true, expires_in: THROTTLE_TTL)
    end
end
