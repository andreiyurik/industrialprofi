site = Rails.application.config.x.site

site.url           = ENV.fetch("SITE_URL", "https://industrialprofi.com")
site.telegram_url  = ENV.fetch("TELEGRAM_URL", "https://t.me/industrialprofi")
site.github_url    = ENV.fetch("GITHUB_URL", "https://github.com/andreiyurik/industrialprofi")
site.author_url    = ENV.fetch("AUTHOR_URL", "https://github.com/andreiyurik")
site.donate_url    = ENV.fetch("DONATE_URL", "https://pay.cloudtips.ru/p/61fe8ef3")
site.contact_email = ENV.fetch("CONTACT_EMAIL", "hello@industrialprofi.com")

# Public payment details but NEVER hardcoded — this repo is public (AGPL).
site.yoomoney_url    = ENV["YOOMONEY_URL"]
site.yoomoney_wallet = ENV["YOOMONEY_WALLET"]
site.card_number     = ENV["CARD_NUMBER"]
site.card_bank       = ENV["CARD_BANK"]

site.boosty_url           = ENV.fetch("BOOSTY_URL", "https://boosty.to/industrialprofi")
site.boosty_supporter_url = ENV.fetch("BOOSTY_SUPPORTER_URL", "https://boosty.to/industrialprofi/purchase/3985879?ssource=DIRECT&share=subscription_link")
site.boosty_ally_url      = ENV.fetch("BOOSTY_ALLY_URL", "https://boosty.to/industrialprofi/purchase/3985880?ssource=DIRECT&share=subscription_link")
site.boosty_pillar_url    = ENV.fetch("BOOSTY_PILLAR_URL", "https://boosty.to/industrialprofi/purchase/3985881?ssource=DIRECT&share=subscription_link")

site.google_site_verification = ENV["GOOGLE_SITE_VERIFICATION"]
site.yandex_verification      = ENV["YANDEX_VERIFICATION"]

site.og_image = ENV["OG_IMAGE_URL"]

# Served at /<key>.txt (see routes.rb) to prove ownership for instant indexing.
site.indexnow_key = ENV["INDEXNOW_KEY"]

# Privacy policy names this provider by name — update it if you swap providers.
site.metrika_id = ENV["YANDEX_METRIKA_ID"]
