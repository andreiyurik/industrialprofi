module Markdown
  QUOTE = /\A(?: {0,3}>[ ]?)*/

  def self.to_html(text, **options)
    Kramdown::Document.new(complete_header_only_tables(text.to_s), input: "GFM", **options).to_html
  end

  # GFM allows a table with no body rows (a fill-in template); kramdown prints it as text, so give it one empty row.
  def self.complete_header_only_tables(text)
    fence = nil
    lines = text.lines
    lines.each_with_index.flat_map do |line, index|
      if fence
        fence = nil if line.match?(/\A {0,3}#{Regexp.escape(fence[0])}{#{fence.size},}[ \t]*\r?\n?\z/)
        next [ line ]
      end
      if (fence = line[/\A {0,3}(`{3,}|~{3,})/, 1])
        next [ line ]
      end
      next [ line ] unless header_only_separator?(lines, index)

      [ line.end_with?("\n") ? line : "#{line}\n", "#{line[/\A[ \t>]*/]}#{empty_row(unquote(line).strip)}\n" ]
    end.join
  end

  def self.header_only_separator?(lines, index)
    line = lines[index]
    return false if index.zero? || unquote(line).match?(/\A(?: {4}|\t)/) || !table_separator?(unquote(line))
    return false unless unquote(lines[index - 1]).include?("|") && !unquote(lines[index + 1].to_s).include?("|")

    index < 2 || unquote(lines[index - 2]).strip.empty?
  end

  def self.table_separator?(content)
    content.include?("|") && content.include?("-") && content.chomp.match?(/\A[ \t|:-]+\z/)
  end

  def self.empty_row(separator)
    cells = separator.delete_prefix("|").delete_suffix("|").split("|").size
    separator.start_with?("|") ? "|#{" |" * cells}" : ([ " " ] * cells).join("|")
  end

  def self.unquote(line) = line.sub(QUOTE, "")
end
