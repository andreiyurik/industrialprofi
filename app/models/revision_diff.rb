require "cgi"

# Word-level diff between two rich-text snapshots, rendered as <ins>/<del>.
#
# Both inputs are HTML; we strip tags down to plain text, tokenise into words
# (whitespace preserved), run a Longest-Common-Subsequence pass, then emit the
# result with added words wrapped in <ins> and removed words in <del>. Every
# token is HTML-escaped before it is wrapped, so the output is safe to render.
#
# A plain word diff is plenty for the size of a single lesson section, so there
# is no need for an external diff library.
class RevisionDiff
  def initialize(before_html, after_html)
    @before = tokenize(plain_text(before_html))
    @after  = tokenize(plain_text(after_html))
  end

  # Marked-up HTML, safe to render.
  def to_html
    segments.map do |op, text|
      escaped = CGI.escapeHTML(text)
      case op
      when :eq  then escaped
      when :del then "<del>#{escaped}</del>"
      when :ins then "<ins>#{escaped}</ins>"
      end
    end.join.html_safe
  end

  # True when the two snapshots carry the same words (whitespace-insensitive).
  def identical?
    @before == @after
  end

  private

  # Collapse the raw LCS edit script into runs of the same operation so we emit
  # one <ins>/<del> per change instead of one per word.
  def segments
    raw = edit_script
    raw.each_with_object([]) do |(op, text), acc|
      if acc.last && acc.last[0] == op
        acc.last[1] += text
      else
        acc << [ op, text ]
      end
    end
  end

  def edit_script
    a, b = @before, @after
    lcs = lcs_table(a, b)
    script = []
    i = 0
    j = 0
    while i < a.length && j < b.length
      if a[i] == b[j]
        script << [ :eq, a[i] ]
        i += 1
        j += 1
      elsif lcs[i + 1][j] >= lcs[i][j + 1]
        script << [ :del, a[i] ]
        i += 1
      else
        script << [ :ins, b[j] ]
        j += 1
      end
    end
    script.concat(a[i..].map { |t| [ :del, t ] }) if i < a.length
    script.concat(b[j..].map { |t| [ :ins, t ] }) if j < b.length
    script
  end

  def lcs_table(a, b)
    table = Array.new(a.length + 1) { Array.new(b.length + 1, 0) }
    (a.length - 1).downto(0) do |i|
      (b.length - 1).downto(0) do |j|
        table[i][j] = if a[i] == b[j]
          table[i + 1][j + 1] + 1
        else
          [ table[i + 1][j], table[i][j + 1] ].max
        end
      end
    end
    table
  end

  # Split into words and whitespace runs, keeping both so the text reconstructs.
  def tokenize(text)
    text.scan(/\S+|\s+/)
  end

  def plain_text(html)
    return "" if html.blank?
    text = ActionController::Base.helpers.strip_tags(html.to_s)
    CGI.unescapeHTML(text)
  end
end
