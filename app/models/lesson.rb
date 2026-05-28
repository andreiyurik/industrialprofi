class Lesson < ApplicationRecord
  belongs_to :path, counter_cache: true
  has_many :resources, -> { order(:position) }, dependent: :destroy
  has_many :lesson_suggestions, dependent: :destroy

  has_rich_text :rich_body
  has_rich_text :rich_description
  has_rich_text :rich_task

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: Path::SLUG_FORMAT }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :kind, inclusion: { in: %w[lesson practice] }

  scope :ordered, -> { order(:position) }

  def to_param
    slug
  end

  def has_description? = rich_description.present? || description.present?
  def has_body?        = rich_body.present? || body.present?
  def has_task?        = rich_task.present? || task.present?
  def has_resources?   = resources.any?

  def prev_in_path
    path.lessons.where("position < ?", position).ordered.last
  end

  def next_in_path
    path.lessons.where("position > ?", position).ordered.first
  end

  def to_markdown
    sections = []
    sections << "# #{title}"
    sections << description if description.present?
    sections << body if body.present?
    if task.present?
      sections << "## Задание"
      sections << task
    end
    sections.join("\n\n")
  end
end
