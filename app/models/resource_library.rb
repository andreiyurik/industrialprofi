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

  Entry = Struct.new(:url, :title, :kind, :required, :lesson_count, keyword_init: true) do
    def required? = required
    def notable? = lesson_count >= NOTABLE_USAGE
  end

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
    # multi-part standards ("…(часть 1)" vs "…(часть 2)") stay separate.
    def merge(group)
      url, title, kind, = group.max_by { |(_u, _t, _k, required, count)| [ type_boolean(required) ? 1 : 0, count ] }
      Entry.new(
        url:, kind:, title: display_title(title),
        required: group.any? { |(_u, _t, _k, required, _c)| type_boolean(required) },
        lesson_count: group.sum { |(_u, _t, _k, _r, count)| count }
      )
    end

    def display_title(title)
      title.to_s.gsub(AUTHORING_NOTE, " ").squeeze(" ").strip
    end

    def dedup_key(title)
      display_title(title).downcase.gsub(/[^a-zа-яё0-9]+/, " ").squeeze(" ").strip
    end

    def rows
      scope.group(:url).pluck(
        Arel.sql("resources.url"),
        Arel.sql("MIN(resources.title)"),
        Arel.sql("MIN(resources.kind)"),
        Arel.sql("MAX(resources.required)"),
        Arel.sql("COUNT(DISTINCT resources.lesson_id)")
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
      [ "resource_library", @path&.id || "all:#{I18n.locale}", *stamp ]
    end

    def type_boolean(value) = ActiveModel::Type::Boolean.new.cast(value)
end
