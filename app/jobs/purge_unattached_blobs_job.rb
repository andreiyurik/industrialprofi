# A direct upload creates a blob the moment an author picks a file — before the
# lesson is saved. If they pick an image then cancel (or never save), the blob
# is left unattached on disk. Purge unattached blobs older than a day so the
# SQLite disk never accretes orphans; attached blobs are never touched. The age
# guard avoids racing a blob between upload and the form submit that attaches it.
class PurgeUnattachedBlobsJob < ApplicationJob
  def perform
    ActiveStorage::Blob.unattached.where(created_at: ..1.day.ago).find_each(&:purge)
  end
end
