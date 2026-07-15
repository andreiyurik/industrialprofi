# The app's design system, hand-translated for email: hex instead of OKLCH, px
# instead of custom properties, a system stack instead of Inter. Keep in step
# with colors.css.
#
# Fizzy styles its mail from a <style> block of classes, which reads far better
# than this. We can't: Fizzy is dark-ink-on-white, so a client that strips
# <style> (Gmail's app on a non-Google mailbox) degrades it to nearly itself. We
# are inverted, and bgcolor attributes survive that stripping while <style>
# doesn't — black ink left on a black ground is an unreadable email. So anything
# carrying colour ships inline; only the safe resets live in the layout's <style>.
module MailerHelper
  FONT_STACK = "system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif".freeze
  MONO_STACK = "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace".freeze

  BACKGROUND = "#000000".freeze   # --color-bg
  SURFACE    = "#0b0b0b".freeze   # --color-subtle-light
  HAIRLINE   = "#292929".freeze   # --color-subtle
  MUTED      = "#929292".freeze   # --color-subtle-dark
  INK        = "#ebebeb".freeze   # --color-ink
  LINK       = "#1a97f4".freeze   # --color-link

  BASE = "margin: 0; font-family: #{FONT_STACK};".freeze
  BODY = "#{BASE} font-size: 16px; line-height: 1.5;".freeze

  # The letter's spine — seal, headline, the one line that says why, the CTA —
  # is centred. Prose, lists and quotes stay left: a centred ragged block is
  # slower to read, and Russian lines are long.
  CENTRED = "text-align: center;".freeze

  STYLES = {
    # Fizzy's title/subtitle pair opens every letter: a heavy headline, then one
    # normal-weight line that says what the mail is for.
    title: "#{BASE} #{CENTRED} color: #{INK}; font-size: 26px; line-height: 1.2; font-weight: 900; letter-spacing: -0.02em; padding-bottom: 12px;",
    subtitle: "#{BASE} #{CENTRED} color: #{INK}; font-size: 18px; line-height: 1.5; font-weight: 400; padding-bottom: 28px;",
    paragraph: "#{BODY} color: #{INK}; padding-bottom: 16px;",
    muted: "#{BASE} #{CENTRED} color: #{MUTED}; font-size: 14px; line-height: 1.5; padding-bottom: 12px;",
    # Metadata in the founder-facing mails ("От:", "Страница:") — a label/value
    # pair reads as a column, not as a centred statement.
    meta: "#{BASE} color: #{MUTED}; font-size: 14px; line-height: 1.5; padding-bottom: 12px;",
    link: "color: #{LINK}; text-decoration: underline;",
    list: "#{BODY} color: #{INK}; padding: 0 0 16px 22px;",
    list_item: "padding-bottom: 6px;",
    quote: "#{BODY} color: #{MUTED}; border-left: 2px solid #{HAIRLINE}; padding: 2px 0 2px 16px; margin-bottom: 16px;",
    rule: "border-top: 1px solid #{HAIRLINE}; font-size: 0; line-height: 0; height: 1px;",
    divider: "border: 0; border-top: 1px solid #{HAIRLINE}; margin: 8px 0 24px;"
  }.freeze

  def mail_style(token)
    STYLES.fetch(token)
  end

  # Links inside translated strings can't carry a style attribute of their own.
  def mail_link_to(name, url)
    link_to name, url, style: mail_style(:link)
  end
end
