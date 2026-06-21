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

# Absolute URL of the default social-share image (1200×630). Blank → og:image is
# omitted and the Twitter card stays "summary". Set OG_IMAGE_URL once you drop a
# branded image in public/ (e.g. https://industrialprofi.com/og.png).
site.og_image = ENV["OG_IMAGE_URL"]

# IndexNow key (Yandex + Bing instant indexing). A random string you generate
# once; it is served at /<key>.txt to prove ownership. Blank → pinging is off.
site.indexnow_key = ENV["INDEXNOW_KEY"]
