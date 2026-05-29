site = Rails.application.config.x.site

site.url           = ENV.fetch("SITE_URL", "https://industrialprofi.com")
site.telegram_url  = ENV.fetch("TELEGRAM_URL", "https://t.me/industrialprofi")
site.github_url    = ENV.fetch("GITHUB_URL", "https://github.com/industrialprofi")
site.author_url    = ENV.fetch("AUTHOR_URL", "https://github.com/yurik2718")
site.donate_url    = ENV.fetch("DONATE_URL", "https://pay.cloudtips.ru/p/61fe8ef3")
site.contact_email = ENV.fetch("CONTACT_EMAIL", "hello@industrialprofi.com")
