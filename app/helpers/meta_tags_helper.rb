module MetaTagsHelper
  def meta_title(text)
    full = "#{text} — industrialprofi.com"
    content_for(:title, full)
    content_for(:og_title, full)
  end

  def meta_description(text)
    content_for(:description, text)
    content_for(:og_description, text)
  end

  def canonical_url(url)
    content_for(:canonical, url)
  end
end
