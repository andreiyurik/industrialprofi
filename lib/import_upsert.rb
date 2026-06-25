# The create-or-refresh decision both curriculum importers share, governing every
# write through the import-freeze rule (see Importable). Given a row and the
# attributes the importer manages, it creates, refreshes-in-place, or leaves a
# human-owned row frozen — so a re-import can never overwrite human work. The two
# importers differ only in bookkeeping (preview status vs report counts), so that
# stays in each caller; the decision tree lives here once.
#
# Returns one of:
#   :created   — new row, created and stamped
#   :updated   — pristine importer-owned row, refreshed (attributes changed)
#   :unchanged — pristine row re-imported with identical content (no save)
#   :frozen    — a human authored or has since edited it; left untouched
#
# `source` stamps provenance (origin). `target_path` is the profession the import
# is writing into; when given, a row found by slug that already belongs to a
# DIFFERENT profession is refused (see CrossPathConflict) instead of silently
# re-parented. An optional block runs ONLY on create, for create-only defaults
# (author, status, position) a refresh must not touch.
module ImportUpsert
  # Base for authoring conflicts an import refuses rather than resolving silently.
  # Callers rescue this one type to surface either conflict to the user.
  class ImportConflict < StandardError; end

  # Slugs are globally unique (flat /lessons/:slug URLs), so a generic title
  # ("Введение", "Техника безопасности") can resolve to a slug another profession
  # already owns. Without this guard, find_or_initialize_by(slug:) would match that
  # foreign row and the import would MOVE it into the profession being imported —
  # silent data loss. We refuse loudly so the author renames or sets a unique slug.
  class CrossPathConflict < ImportConflict
    def initialize(record, target_path)
      owner = record.try(:path)&.title || "id=#{record.try(:path_id)}"
      super("slug «#{record.slug}» уже принадлежит другой профессии (#{owner}) — " \
            "переименуйте запись или задайте уникальный slug")
    end
  end

  # Two items in ONE import that resolve to the same slug: the second
  # find_or_initialize_by(slug:) would reuse the first's row and silently merge
  # them (the earlier one's content is lost). Refuse instead.
  class DuplicateSlugConflict < ImportConflict
    def initialize(record)
      super("несколько записей сводятся к одному slug «#{record.slug}» " \
            "(#{record.class.model_name.human}) — задайте одной явный уникальный slug")
    end
  end

  def import_upsert(record, source, attrs, target_path: nil)
    guard_cross_path!(record, target_path)
    return :frozen if record.persisted? && record.frozen_for_import?

    creating = record.new_record?
    record.assign_attributes(attrs)
    yield record if creating && block_given?
    record.stamp_import!(source)

    if creating
      record.save!
      :created
    elsif record.changed?
      record.save!
      :updated
    else
      :unchanged
    end
  end

  # Claim a slug for the current run via the caller-owned `seen` set, raising if it
  # was already claimed. Paths are exempt (reuse-by-slug there is intentional), so
  # the caller simply doesn't call this for a path.
  def claim_slug!(seen, record)
    return if record.slug.blank?

    raise DuplicateSlugConflict.new(record) unless seen.add?([ record.class.name, record.slug ])
  end

  private
    # A persisted row found by slug that lives under a different profession would
    # be silently re-parented (the import reassigns its course/path). Refuse. Paths
    # sit at the top — reuse-by-slug there is intentional, so callers pass no
    # target_path for a path and this is skipped.
    def guard_cross_path!(record, target_path)
      return unless target_path && record.persisted? && record.respond_to?(:path_id)

      owner_path_id = record.path_id
      return if owner_path_id.nil? || owner_path_id == target_path.id

      raise CrossPathConflict.new(record, target_path)
    end
end
