module SiteHelper
  def site_config
    Rails.application.config.x.site
  end
end
