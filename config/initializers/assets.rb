# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# The 60-odd files in app/assets/stylesheets are INPUTS to the dartsass build,
# not assets — app/assets/builds/application.css is the only one a page links
# (see application.scss). On the load path they were each digested into
# public/assets too: ~300 KB of files in the production image that no page can
# request. Builds, images and fonts stay on the path, so `url()` inside the
# built file still resolves.
Rails.application.config.assets.excluded_paths << Rails.root.join("app/assets/stylesheets")
