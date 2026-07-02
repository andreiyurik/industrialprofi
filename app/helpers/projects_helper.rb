module ProjectsHelper
  # Practice titles often carry a "Практика:" prefix or ": практика" tail —
  # redundant on a page that is entirely practice, and the repetition reads
  # machine-made.
  def project_title(lesson)
    lesson.title.sub(/\Aпрактика\s*[:—–-]\s*/i, "").sub(/\s*[:—–-]\s*практика\z/i, "")
  end
end
