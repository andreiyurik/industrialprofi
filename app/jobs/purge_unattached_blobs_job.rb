# Blobs go unattached if an author picks a file then cancels/never saves. Purge those older
# than a day so disk doesn't accrete orphans; the age guard avoids racing an in-flight upload.
class PurgeUnattachedBlobsJob < ApplicationJob
  def perform
    ActiveStorage::Blob.unattached.where(created_at: ..1.day.ago).find_each(&:purge)
  end
end
