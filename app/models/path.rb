class Path < ApplicationRecord
  include IndexNowNotifiable
  include Importable
  include Sluggable
  include Curriculum
  include Landing
  include Maturity

  SLUG_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  # draft/pending_review = not public; published = live. A profession with no
  # content is not a Path: the catalog's "ждут автора" list is plain copy
  # (ru.yml → paths.soon_wanted), so nothing empty lives in the DB or the admin.
  STATUSES = %w[draft pending_review published].freeze

  # role = full career path from scratch ("Электрик", "Инженер АСУ ТП");
  # skill = specific tool/technology for working professionals ("Siemens TIA Portal", "SCADA").
  KINDS = %w[role skill].freeze

  # Fields the YAML/AI importer manages (and digests for edit-safety). The slug
  # is the stable key, not content. The landing rides here too: a pack's
  # landing.yml refreshes a pristine profession and never touches one an
  # expert has edited (any landing edit changes the digest → frozen).
  IMPORTABLE_FIELDS = %w[title description position status kind landing].freeze

  # inverse_of is explicit because a scoped has_many gets no automatic detection —
  # without it `course.icon` falling back to `path.icon` would re-query per card.
  has_many :courses, -> { order(:position) }, dependent: :destroy, inverse_of: :path
  # NO dependent: :destroy here on purpose — Course owns the lesson destroy chain
  # (path → courses → lessons). Adding it back would destroy each lesson twice.
  # This association stays for total counts / catalog-wide lesson queries.
  has_many :lessons, -> { order(:position) }
  # Practice lessons only — the journal links a practice task you did, not theory,
  # which keeps the "Связанная статья" picker short (see journal form).
  has_many :practice_lessons, -> { practice.ordered }, class_name: "Lesson"
  # Editors granted direct edit access to this profession (see Editorship).
  has_many :editorships, dependent: :destroy
  has_many :editors, through: :editorships, source: :user
  # Editors who opted in to be shown publicly as curators of this profession
  # Whoever holds a grant is named on the map: curating is a public role, not
  # an opt-in — a map is never anonymous, a person answers for it.
  has_many :curators, -> { active.order(:name) }, through: :editorships, source: :user
  belongs_to :author, class_name: "User", optional: true

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :status, inclusion: { in: STATUSES }
  validates :icon, inclusion: { in: ->(_) { Icon.emblems } }, allow_blank: true
  validates :kind, inclusion: { in: KINDS }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :locale, presence: true, format: { with: /\A[a-z]{2}\z/ }

  scope :published, -> { where(status: "published") }
  scope :official, -> { where(author_id: nil) }
  scope :community, -> { where.not(author_id: nil) }
  scope :ordered, -> { order(:position) }
  scope :with_practice_lessons, -> { where(id: Lesson.practice.select(:path_id)) }
  # Professions a user may edit in the admin: admins see all, editors only the
  # ones granted to them. Backs the scoped admin index pages.
  scope :editable_by, ->(user) {
    user.administrator? ? all : where(id: user.editorships.select(:path_id))
  }
  # Each language market gets its own paths (TOP model, not synced translations) —
  # the catalog only ever lists the current locale's maps.
  scope :localized, ->(locale = I18n.locale) { where(locale: locale) }

  # path_id => published-course count, for the catalog cards' meta line
  # (the courses_count counter cache also counts coming-soon stubs).
  def self.published_course_counts
    Course.where(status: "published").group(:path_id).count
  end

  def to_param
    slug
  end

  # `icon` is the stored choice and may be blank; `emblem` is what to render. Kept
  # separate on purpose — overriding the attribute reader would make `allow_blank`
  # and form checkedness read the fallback instead of the choice.
  def emblem
    icon.presence || Icon::DEFAULT_EMBLEM
  end

  # The hub shows a «Словарь» tab only for a profession whose lessons define
  # abbreviations — derived from data, not a setting.
  def has_glossary? = GlossaryTerm.for_path(self).exists?

  # Everyone whose proposed edit or source was accepted into this map — the
  # hub's «карту улучшили» credit. Names, not scores: attribution is the one
  # recognition mechanic here (no leaderboard, by decision). A guest's
  # proposal carries only author_name, a member's their account name.
  def contributor_names
    [ LessonSuggestion, ResourceSuggestion ].flat_map { |model|
      model.approved.joins(:lesson).left_joins(:user).where(lessons: { path_id: id })
           .pluck(Arel.sql("COALESCE(users.name, #{model.table_name}.author_name)"))
    }.compact_blank.uniq
  end

  # The contributors who have accounts — for the hub header's avatar stack
  # (guests' proposals count in contributor_names but have no face to show).
  def contributor_users(limit: 3)
    ids = [ LessonSuggestion, ResourceSuggestion ].flat_map { |model|
      model.approved.joins(:lesson).where(lessons: { path_id: id }).where.not(user_id: nil).distinct.pluck(:user_id)
    }.uniq
    User.where(id: ids).order(:name).limit(limit)
  end

  private
    def indexnow_url
      "#{indexnow_site_url}/paths/#{slug}" if status == "published"
    end

    def indexnow_should_ping?
      saved_change_to_status? || saved_change_to_title? ||
        saved_change_to_description? || saved_change_to_slug?
    end
end
