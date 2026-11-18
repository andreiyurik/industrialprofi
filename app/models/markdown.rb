module Markdown
  def self.to_html(text, **options)
    Kramdown::Document.new(complete_header_only_tables(text.to_s), input: "GFM", **options).to_html
  end

  # GFM allows a table with no body rows (a fill-in template); kramdown prints it as text, so give it one empty row.
  def self.complete_header_only_tables(text)
    fenced = false
    lines = text.lines
    lines.each_with_index.flat_map do |line, index|
      fenced = !fenced if line.lstrip.start_with?("```", "~~~")
      next [ line ] if fenced || !table_separator?(line) || index.zero? || !lines[index - 1].include?("|") || lines[index + 1].to_s.include?("|")

      cells = line.strip.delete_prefix("|").delete_suffix("|").split("|").size
      [ line.end_with?("\n") ? line : "#{line}\n", "|#{" |" * cells}\n" ]
    end.join
  end

  def self.table_separator?(line)
    line.include?("|") && line.include?("---") && line.chomp.match?(/\A[ \t|:-]+\z/)
  end
end
