module ProjectsHelper
  # Strips a redundant "Практика:" prefix/tail (reads machine-made on an all-practice page).
  # Re-raises the first letter after stripping; only that char is upcased, so acronyms stay intact.
  def project_title(lesson)
    lesson.title.sub(/\Aпрактика\s*[:—–-]\s*/i, "").sub(/\s*[:—–-]\s*практика\z/i, "")
          .sub(/\A[[:lower:]]/) { $&.upcase }
  end
end
