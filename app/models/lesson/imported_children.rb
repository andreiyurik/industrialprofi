# A lesson's resources and abbreviations as they arrive from a pack — the one
# place both import engines (the seed tree and a pasted/zipped document) sync
# them, so the rules can't drift: matched by title/mark, a human-owned row is
# never touched, a new row takes the import's origin. Called only while the
# lesson itself is still importer-owned (the freeze lives on the parent).
module Lesson::ImportedChildren
  extend ActiveSupport::Concern

  # => { "resources_created" => n, "resources_updated" => n,
  #      "glossary_terms_created" => n, "glossary_terms_updated" => n }
  def import_children(resources:, terms:, source:)
    counts = Hash.new(0)

    Array(resources).each_with_index do |data, index|
      sync_child(self.resources.find_or_initialize_by(title: data["title"]), source, counts, "resources") do |resource|
        resource.assign_attributes(
          url: data["url"], kind: data["kind"].presence || "document",
          required: data.fetch("required", false), position: index + 1,
          country_code: data["country_code"], language: data["language"], note: data["note"]
        )
      end
    end

    Array(terms).each do |data|
      sync_child(glossary_terms.find_or_initialize_by(abbr: data["term"]), source, counts, "glossary_terms") do |term|
        term.assign_attributes(full: data["full"], note: data["note"], analog: data["analog"])
      end
    end

    counts
  end

  private
    def sync_child(child, source, counts, table)
      return if child.persisted? && child.origin == "human"

      yield child
      if child.new_record?
        child.origin = source
        child.save!
        counts["#{table}_created"] += 1
      elsif child.changed?
        child.save!
        counts["#{table}_updated"] += 1
      end
    end
end
