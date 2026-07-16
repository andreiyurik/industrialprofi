# A grant: this user may directly edit this profession — its courses, lessons,
# resources, revisions and suggestions. Access is separate from authorship:
# `paths.author_id` records who created a path (official vs community), an
# Editorship records who may maintain it. Admins edit everything and need none.
#
# Cross-profession contribution still flows through the open suggest → review
# pipeline: an editor without an editorship is, for that profession, an ordinary
# contributor who suggests edits the owner reviews.
class Editorship < ApplicationRecord
  belongs_to :user
  belongs_to :path

  validates :user_id, uniqueness: { scope: :path_id }

  # The self-sufficiency compass: how many published professions are maintained
  # by someone besides the founder. Counts only while an active editor role
  # backs the grant — the same rule User#can_edit_path? applies.
  def self.count_published_paths_with_editor
    joins(:user).merge(User.active.where(role: :editor))
                .where(path_id: Path.published.select(:id))
                .distinct.count(:path_id)
  end
end
