module SeoHelper
  SITE_NAME = "IndustrialProfi"

  def learning_resource_json_ld(lesson)
    data = {
      "@context": "https://schema.org",
      "@type": "LearningResource",
      name: lesson.title,
      description: lesson.description.to_s.truncate(160),
      provider: { "@type": "Organization", name: SITE_NAME },
      inLanguage: "ru",
      isPartOf: { "@type": "Course", name: lesson.course.title },
      url: "#{site_url}/lessons/#{lesson.slug}"
    }
    data.to_json
  end

  # Profession landing page (a program made of courses).
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
      url: "#{site_url}/paths/#{path.slug}"
    }
    data.to_json
  end

  # A single course page.
  def course_page_json_ld(course)
    data = {
      "@context": "https://schema.org",
      "@type": "Course",
      name: course.title,
      description: course.description.to_s.truncate(160),
      provider: { "@type": "Organization", name: SITE_NAME },
      numberOfLessons: course.lessons_count,
      inLanguage: "ru",
      isAccessibleForFree: true,
      url: "#{site_url}/courses/#{course.slug}"
    }
    data.to_json
  end

  def website_json_ld
    data = {
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: SITE_NAME,
      url: site_url,
      description: I18n.t("site.description")
    }
    data.to_json
  end

  # Brand entity for the SERP/knowledge graph — ties the name, logo and official
  # channels together so Google/Yandex recognise "IndustrialProfi" as one org.
  def organization_json_ld
    site = Rails.application.config.x.site
    data = {
      "@context": "https://schema.org",
      "@type": "EducationalOrganization",
      name: SITE_NAME,
      url: site_url,
      logo: "#{site_url}/icon.png",
      description: I18n.t("site.description"),
      sameAs: [ site.telegram_url, site.github_url ].compact
    }
    data.to_json
  end

  private

  def site_url
    Rails.application.config.x.site.url
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
    safe = json_string.gsub("</", '<\/')
    tag.script(safe.html_safe, type: "application/ld+json")
  end
end
