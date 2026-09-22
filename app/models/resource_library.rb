class ResourceLibrary
  NOTABLE_USAGE = 3

  # Internal authoring notes leaked into titles; stripped from display and ignored when deduping.
  AUTHORING_NOTE = /\s*\((?:для аудита|для самопроверки|аудит|черновик)\)\s*/i

  # Bump when Entry's shape changes — Solid Cache survives deploys.
  CACHE_VERSION = 2

  Entry = Struct.new(:url, :title, :kind, :required, :lessons, keyword_init: true) do
    def required? = required
    def lesson_count = lessons.size
    def notable? = lesson_count >= NOTABLE_USAGE
  end

  LessonRef = Struct.new(:slug, :title, keyword_init: true)

  def self.for(path: nil, version: nil) = new(path:, version:).entries

  def self.version(locale: I18n.locale)
    scope = Resource.published.where(paths: { locale: locale })
    [ scope.count, scope.maximum(:updated_at)&.to_f ]
  end

  def initialize(path:, version: nil)
    @path = path
    @version = version
  end

  def entries
    Rails.cache.fetch(cache_key) { build }
  end

  private
    def build
      rows.group_by { |row| dedup_key(row[1]) }
          .reject { |key, _group| key.blank? }
          .map { |_key, group| merge(group) }
          .sort_by { |entry| [ entry.required? ? 0 : 1, -entry.lesson_count, entry.title.downcase ] }
    end

    # Multi-part standards ("…часть 1"/"часть 2") stay separate — titles normalize to distinct keys.
    def merge(group)
      best = group.max_by { |(url, _t, _k, required, _s, _lt)| [ type_boolean(required) ? 1 : 0, group.count { |r| r[0] == url } ] }
      lessons = group.map { |(_u, _t, _k, _r, slug, title)| LessonRef.new(slug:, title:) }
                     .uniq(&:slug)
                     .sort_by { |ref| ref.title.to_s.downcase }
      Entry.new(
        url: best[0], kind: best[2], title: display_title(best[1]),
        required: group.any? { |(_u, _t, _k, required, _s, _lt)| type_boolean(required) },
        lessons: lessons
      )
    end

    def display_title(title)
      title.to_s.gsub(AUTHORING_NOTE, " ").squeeze(" ").strip
    end

    def dedup_key(title)
      display_title(title).downcase.gsub(/[^a-zа-яё0-9]+/, " ").squeeze(" ").strip
    end

    def rows
      scope.pluck(
        Arel.sql("resources.url"),
        Arel.sql("resources.title"),
        Arel.sql("resources.kind"),
        Arel.sql("resources.required"),
        Arel.sql("lessons.slug"),
        Arel.sql("lessons.title")
      )
    end

    def scope
      base = Resource.published
      @path ? base.where(lessons: { path_id: @path.id }) : base.where(paths: { locale: I18n.locale })
    end

    def cache_key
      stamp = @version || [ scope.count, scope.maximum(:updated_at)&.to_f ]
      [ "resource_library", CACHE_VERSION, @path&.id || "all:#{I18n.locale}", *stamp ]
    end

    def type_boolean(value) = ActiveModel::Type::Boolean.new.cast(value)
end
