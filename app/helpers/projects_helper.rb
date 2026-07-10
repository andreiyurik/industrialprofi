module ProjectsHelper
  # Practice titles often carry a "Практика:" prefix or ": практика" tail —
  # redundant on a page that is entirely practice, and the repetition reads
  # machine-made.
  # Stripping the prefix can leave the title lowercase mid-sentence — re-raise
  # the first letter (upcase only that character; acronyms stay intact).
  def project_title(lesson)
    lesson.title.sub(/\Aпрактика\s*[:—–-]\s*/i, "").sub(/\s*[:—–-]\s*практика\z/i, "")
          .sub(/\A[[:lower:]]/) { $&.upcase }
  end
end
