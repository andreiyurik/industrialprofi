# Professional abbreviations, decoded («ПУЭ — Правила устройства
# электроустановок») — the /glossary reference page. Like the calculators
# registry, this is static reference data, NOT user content: it lives in
# config/glossary.yml and is edited by commit (git = its history), so there is
# no table, no admin and no ops surface. Scope is deliberately narrow —
# abbreviations with расшифровка and one line of context; explaining concepts
# is the lessons' job, and each entry routes there (or to full-text search).
class Glossary
  Term = Data.define(:abbr, :full, :note, :lesson, :analog) do
    # Anchor within the group («elektrik-ПУЭ») — Cyrillic ids are valid HTML.
    def anchor = abbr.gsub(/[\s,]+/, "-")

    # Derived, not authored: any Cyrillic in the abbreviation marks it as
    # русскоязычное (ГОСТ/приказы, incl. mixed marks like ВВГнг(А)-LS),
    # otherwise it's international (IEC/EN). Keeps the YAML free of a field
    # nobody should have to maintain by hand.
    def script = abbr.match?(/\p{Cyrillic}/) ? "ru" : "int"
  end

  # => [[Path, [Term, …]], …] in catalog order. Groups whose profession isn't
  # published are skipped; a term whose lesson slug doesn't resolve keeps
  # lesson: nil and the page falls back to search — links never rot.
  def self.grouped
    data = YAML.load_file(Rails.root.join("config/glossary.yml")) || {}
    lessons = Lesson.where(slug: data.values.flatten.filter_map { it["lesson"] }).index_by(&:slug)

    Path.published.localized.where(slug: data.keys).ordered.map do |path|
      terms = data.fetch(path.slug).map do |entry|
        Term.new(abbr: entry.fetch("term"), full: entry.fetch("full"),
                 note: entry["note"], lesson: lessons[entry["lesson"]],
                 analog: entry["analog"])
      end
      [ path, terms ]
    end
  end
end
