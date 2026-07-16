# Deduplicated, ranked aggregate of resources across published content — the
# data behind the public /resources library and the per-profession section.
#
# Pure derivation from existing Resource rows: no new model, no curation column.
# Same URL referenced by many lessons collapses to ONE entry ("в N уроках").
# "Top" is automatic and self-curating: required (★) first, then by how many
# lessons reference it. Cached (Solid Cache), keyed by content version, per the
# scaling seam in CLAUDE.md.
class ResourceLibrary
  # A resource counts as "notable" (cross-cutting) only when several lessons
  # reference it; below this the count is noise and isn't shown. It also gates
  # whether the hub bothers showing a profession's preview.
  NOTABLE_USAGE = 3

  # Internal authoring notes that leaked into resource titles; stripped from the
  # public display (and ignored when de-duplicating).
  AUTHORING_NOTE = /\s*\((?:для аудита|для самопроверки|аудит|черновик)\)\s*/i

  # Bump when Entry's shape changes, so a deploy doesn't hand back cached
  # Entries built by the old code (Solid Cache survives deploys).
  CACHE_VERSION = 2

  Entry = Struct.new(:url, :title, :kind, :required, :lessons, keyword_init: true) do
    def required? = required
    def lesson_count = lessons.size
    def notable? = lesson_count >= NOTABLE_USAGE
  end

  # A lesson that references the resource — just enough to link back to it.
  LessonRef = Struct.new(:slug, :title, keyword_init: true)

  def self.for(path: nil, version: nil) = new(path:, version:).entries

  # A single stamp for the whole live set, computed once and shared across every
  # profession on the hub — so the hub pays two aggregates total instead of two
  # per profession on each render. Coarser than a per-path key (any live change
  # busts every hub entry), which is the right trade for a cached aggregate page.
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
    # Lead by the real editorial signal — ★ required — then by reference count as
    # a quiet tie-breaker. Frequency is NOT advertised as importance: it just
    # orders within the required/optional tiers.
    def build
      rows.group_by { |row| dedup_key(row[1]) }
          .reject { |key, _group| key.blank? }
          .map { |_key, group| merge(group) }
          .sort_by { |entry| [ entry.required? ? 0 : 1, -entry.lesson_count, entry.title.downcase ] }
    end

    # Same document entered under different URLs (a common content slip) collapses
    # to one entry. Conservative: only identical normalized titles merge, so
    # multi-part standards ("…(часть 1)" vs "…(часть 2)") stay separate. The
    # representative url/title/kind come from the required (or most-repeated) row;
    # the lessons are every distinct lesson across the merged rows.
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

    # One row per resource (grouping/dedup happens in Ruby by normalized title),
    # carrying the parent lesson so the library can link back to it.
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

    # Invalidates whenever a live resource is added/removed/edited, or a path or
    # course is (un)published (which changes the live set's size). The hub passes
    # a shared @version so it doesn't recompute the stamp per profession.
    def cache_key
      stamp = @version || [ scope.count, scope.maximum(:updated_at)&.to_f ]
      [ "resource_library", CACHE_VERSION, @path&.id || "all:#{I18n.locale}", *stamp ]
    end

    def type_boolean(value) = ActiveModel::Type::Boolean.new.cast(value)
end
