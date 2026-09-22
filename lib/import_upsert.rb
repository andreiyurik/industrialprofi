# Create-or-refresh shared by both curriculum importers; a human-edited row stays frozen.
module ImportUpsert
  class ImportConflict < StandardError; end

  # Guards find_or_initialize_by(slug:) against silently moving a foreign-profession row.
  class CrossPathConflict < ImportConflict
    def initialize(record, target_path)
      owner = record.try(:path)&.title || "id=#{record.try(:path_id)}"
      super("slug «#{record.slug}» уже принадлежит другой профессии (#{owner}) — " \
            "переименуйте запись или задайте уникальный slug")
    end
  end

  # Two items in one import resolving to the same slug would silently merge — refuse.
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

  def claim_slug!(seen, record)
    return if record.slug.blank?

    raise DuplicateSlugConflict.new(record) unless seen.add?([ record.class.name, record.slug ])
  end

  private
    def guard_cross_path!(record, target_path)
      return unless target_path && record.persisted? && record.respond_to?(:path_id)

      owner_path_id = record.path_id
      return if owner_path_id.nil? || owner_path_id == target_path.id

      raise CrossPathConflict.new(record, target_path)
    end
end
