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
# `source` stamps provenance (origin). An optional block runs ONLY on create, for
# create-only defaults (author, status, position) a refresh must not touch.
module ImportUpsert
  def import_upsert(record, source, attrs)
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
end
