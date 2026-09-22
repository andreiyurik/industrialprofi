require "shellwords"

# Every probe is defensive — returns nil, never raises into the dashboard render.
class SystemStatus
  DISK_WARN_THRESHOLD = 1.gigabyte

  # Includes -wal/-shm sidecars — the real on-disk footprint.
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

  def jobs
    {
      # Failed jobs keep finished_at NULL, so exclude them here or both numbers double-count.
      pending: SolidQueue::Job.where(finished_at: nil).where.missing(:failed_execution).count,
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

    def df_fields
      @df_fields ||= `df -kP #{Shellwords.escape(database_dir)} 2>/dev/null`.lines.last&.split || []
    end

    def field_bytes(index)
      value = df_fields[index]
      value&.match?(/\A\d+\z/) ? value.to_i * 1024 : nil
    end
end
