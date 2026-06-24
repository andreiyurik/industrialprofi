require "shellwords"

# Read-only snapshot of the single VPS's health for the admin dashboard — the
# numbers that guard the one thing that can take down a one-server SQLite app:
# a full disk. Plus background-job health (production-only, where Solid Queue
# runs in its own database). Every probe is defensive: if it can't run, it
# returns nil and the dashboard hides that line — it never raises into a render.
class SystemStatus
  # Free space below this is flagged: time to act before the disk fills.
  DISK_WARN_THRESHOLD = 1.gigabyte

  # Sum of every SQLite file in the database directory — the primary DB plus the
  # Solid Queue/Cache/Cable databases and their -wal/-shm sidecars. This is the
  # real on-disk footprint, unlike Active Storage blobs (≈0 since uploads were
  # removed), so it's the honest "is the database growing" number.
  def database_bytes
    Dir.glob(File.join(database_dir, "*.sqlite3*")).sum { |file| File.size(file) }
  rescue StandardError
    nil
  end

  def disk_free_bytes  = field_bytes(3) # df "Available"
  def disk_total_bytes = field_bytes(1) # df "1024-blocks" (total)

  def disk_low?
    free = disk_free_bytes
    free.present? && free < DISK_WARN_THRESHOLD
  end

  # { pending:, failed: } or nil when Solid Queue isn't reachable here (dev/test
  # share the primary DB and have no queue tables — this is a production signal).
  # `failed` is the alarm: a job dying silently (e.g. the signup-code mailer)
  # breaks a user flow with no other warning.
  def jobs
    {
      pending: SolidQueue::Job.where(finished_at: nil).count,
      failed:  SolidQueue::FailedExecution.count
    }
  rescue StandardError
    nil
  end

  private
    def database_dir
      path = ActiveRecord::Base.connection_db_config.database.to_s
      path = Rails.root.join(path).to_s unless path.start_with?("/")
      File.dirname(path)
    end

    # One `df` call per request, memoized; columns of the portable (-P) format.
    def df_fields
      @df_fields ||= `df -kP #{Shellwords.escape(database_dir)} 2>/dev/null`.lines.last&.split || []
    end

    def field_bytes(index)
      value = df_fields[index]
      value&.match?(/\A\d+\z/) ? value.to_i * 1024 : nil
    end
end
