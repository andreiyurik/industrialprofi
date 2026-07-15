module PostsHelper
  # A news post body flows through the SAME prose enrichment as lessons
  # (callouts, code blocks, scrollable tables, figures), so a post reads
  # identically to an article — one rendering pipeline, no duplicate logic.
  def post_body(post)
    enrich_prose(post.rich_body.to_s).to_s.html_safe
  end

  # Telegram share deep-link — same builder as the milestone dialog.
  def telegram_share_url(url:, text:)
    "https://t.me/share/url?#{ { url: url, text: text }.to_query }"
  end

  NOMINATIVE_MONTHS = %w[
    Январь Февраль Март Апрель Май Июнь
    Июль Август Сентябрь Октябрь Ноябрь Декабрь
  ].freeze

  # A nominative "Июль 2026" group header — I18n's date.month_names are
  # genitive (built for "15 июля"), which reads wrong without a day attached.
  def post_month_label(date)
    "#{NOMINATIVE_MONTHS[date.month - 1]} #{date.year}"
  end
end
