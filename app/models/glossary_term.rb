class GlossaryTerm < ApplicationRecord
  belongs_to :lesson

  validates :abbr, presence: true, length: { maximum: 40 }, uniqueness: { scope: :lesson_id }
  validates :full, presence: true, length: { maximum: 200 }
  validates :note, length: { maximum: 200 }
  validates :analog, length: { maximum: 40 }
  # Provenance only — edit-safety rides on the parent lesson's freeze.
  validates :origin, inclusion: { in: Importable::ORIGINS }
  validate :single_definition_per_profession

  # Cyrillic marks sort first, then international, each run alphabetical.
  scope :alphabetical, -> { order(Arel.sql("CASE WHEN abbr GLOB '*[А-яЁё]*' THEN 0 ELSE 1 END, abbr")) }
  scope :published, -> {
    joins(lesson: [ :course, :path ])
      .where(courses: { status: "published" }, paths: { status: "published" })
  }

  def self.for_path(path)
    published.where(lessons: { path_id: path.id }).includes(:lesson).alphabetical
  end

  def self.by_path(locale: I18n.locale)
    published.where(paths: { locale: locale }).includes(lesson: :path).alphabetical
             .group_by { |term| term.lesson.path }
             .sort_by { |path, _terms| path.position }
  end

  # Slashes/spaces fold to dashes — a "/" id breaks CSS selectors and URLs.
  def anchor = abbr.gsub(%r{[\s,/]+}, "-")

  def script = abbr.match?(/\p{Cyrillic}/) ? "ru" : "int"

  private
    def single_definition_per_profession
      return if abbr.blank? || lesson.nil?

      other = GlossaryTerm.joins(:lesson).where(lessons: { path_id: lesson.path_id }, abbr: abbr)
                          .where.not(lesson_id: lesson_id).includes(:lesson).first
      errors.add(:abbr, :defined_elsewhere, lesson: other.lesson.title) if other
    end
end
