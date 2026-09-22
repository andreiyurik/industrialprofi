# Access is separate from authorship: `paths.author_id` records who created a
# path, an Editorship records who may maintain it. Admins edit everything and
# need none. Without a grant, an editor is an ordinary suggest → review contributor.
class Editorship < ApplicationRecord
  belongs_to :user
  belongs_to :path

  validates :user_id, uniqueness: { scope: :path_id }

  # Counts only while an active editor role backs the grant, same as User#can_edit_path?.
  def self.count_published_paths_with_editor
    joins(:user).merge(User.active.where(role: :editor))
                .where(path_id: Path.published.select(:id))
                .distinct.count(:path_id)
  end

  # Active non-admins not already granted; admins need no seat.
  def self.candidates_for(path)
    User.active.where.not(role: :administrator)
        .where.not(id: path.editorships.select(:user_id)).order(:name)
  end
end
