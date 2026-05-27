module SeoHelper
  SITE_NAME = "IndustrialProfi"
  SITE_URL = "https://industrialprofi.com"

  def learning_resource_json_ld(lesson)
    data = {
      "@context": "https://schema.org",
      "@type": "LearningResource",
      name: lesson.title,
      description: lesson.description.to_s.truncate(160),
      provider: { "@type": "Organization", name: SITE_NAME },
      inLanguage: "ru",
      isPartOf: { "@type": "Course", name: lesson.path.title },
      url: "#{SITE_URL}/lessons/#{lesson.slug}"
    }
    data.to_json
  end

  def course_json_ld(path)
    data = {
      "@context": "https://schema.org",
      "@type": "Course",
      name: path.title,
      description: path.description.to_s.truncate(160),
      provider: { "@type": "Organization", name: SITE_NAME },
      numberOfLessons: path.lessons_count,
      inLanguage: "ru",
      isAccessibleForFree: true,
      url: "#{SITE_URL}/paths/#{path.slug}"
    }
    data.to_json
  end

  def website_json_ld
    data = {
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: SITE_NAME,
      url: SITE_URL,
      description: I18n.t("site.description")
    }
    data.to_json
  end

  def breadcrumb_json_ld(crumbs)
    items = crumbs.each_with_index.map do |crumb, i|
      {
        "@type": "ListItem",
        position: i + 1,
        name: crumb[:title],
        item: crumb[:url]
      }
    end

    data = {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: items
    }
    data.to_json
  end

  def json_ld_tag(json_string)
    tag.script(json_string.html_safe, type: "application/ld+json")
  end
end
