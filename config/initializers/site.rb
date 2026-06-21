site = Rails.application.config.x.site

site.url           = ENV.fetch("SITE_URL", "https://industrialprofi.com")
site.telegram_url  = ENV.fetch("TELEGRAM_URL", "https://t.me/industrialprofi")
site.github_url    = ENV.fetch("GITHUB_URL", "https://github.com/yurik2718/industrialprofi")
site.author_url    = ENV.fetch("AUTHOR_URL", "https://github.com/yurik2718")
site.donate_url    = ENV.fetch("DONATE_URL", "https://pay.cloudtips.ru/p/61fe8ef3")
site.contact_email = ENV.fetch("CONTACT_EMAIL", "hello@industrialprofi.com")

# Search-engine ownership verification (Google Search Console / Яндекс.Вебмастер).
# These codes are public by design (they ship in a <head> meta tag); set them via
# ENV at deploy time. Blank = the tag is simply omitted. No tracking — these
# consoles only report what the crawlers already do.
site.google_site_verification = ENV["GOOGLE_SITE_VERIFICATION"]
site.yandex_verification      = ENV["YANDEX_VERIFICATION"]
