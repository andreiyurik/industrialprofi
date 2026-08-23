module SeoHelper
  SITE_NAME = "IndustrialProfi"

  # og:locale wants a territory ("ru_RU"); fall back to the bare code for
  # locales we haven't mapped yet.
  OG_LOCALES = { ru: "ru_RU", en: "en_US", kk: "kk_KZ" }.freeze

  def og_locale
    OG_LOCALES.fetch(I18n.locale, I18n.locale.to_s)
  end

  # Chrome pages (UI-only, same page in every language) get hreflang pairs;
  # content pages live in ONE locale (Path#locale) and get none. Query-string
  # variants (?path=) point at locale-bound data, so they are excluded too.
  def bilingual_page?
    request.get? && request.query_parameters.blank? &&
      (controller_name == "pages" ||
       (action_name == "index" && controller_name.in?(%w[paths projects resources calculators])) ||
       (controller_name == "calculators" && action_name == "show") ||
       (controller_name == "business_inquiries" && action_name == "new"))
  end

  def alternate_locale_links
    return unless bilingual_page?

    links = I18n.available_locales.map do |locale|
      tag.link(rel: "alternate", hreflang: locale, href: url_for(locale: locale, only_path: false))
    end
    # x-default = the language-neutral entry; today that's the default locale.
    links << tag.link(rel: "alternate", hreflang: "x-default",
                      href: url_for(locale: I18n.default_locale, only_path: false))
    safe_join(links, "\n    ")
  end

  # Rack keeps the raw query string BINARY, so bot-sent unencoded bytes would
  # crash UTF-8 template rendering — retag and scrub before echoing the URL.
  def og_url
    content_for(:canonical) || request.original_url.force_encoding(Encoding::UTF_8).scrub
  end

  def learning_resource_json_ld(lesson)
    data = {
      "@context": "https://schema.org",
      "@type": "LearningResource",
      name: lesson.title,
      description: lesson.description.to_s.truncate(160),
      provider: { "@type": "Organization", name: SITE_NAME },
      author: { "@type": "Organization", name: SITE_NAME },
      inLanguage: I18n.locale.to_s,
      isPartOf: { "@type": "Course", name: lesson.course.title },
      datePublished: lesson.created_at.iso8601,
      dateModified: lesson.updated_at.iso8601,
      url: "#{site_url}/#{I18n.locale}/lessons/#{lesson.slug}"
    }
    # E-E-A-T: the profession's curators vouch for the material.
    # Emitted only when a real person actually stands behind the map.
    curators = lesson.path.curators.to_a
    if curators.any?
      data[:reviewedBy] = curators.map do |curator|
        { "@type": "Person", name: curator.name, jobTitle: curator.headline.presence }.compact
      end
    end
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
      inLanguage: I18n.locale.to_s,
      isAccessibleForFree: true,
      url: "#{site_url}/#{I18n.locale}/paths/#{path.slug}"
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
      inLanguage: I18n.locale.to_s,
      isAccessibleForFree: true,
      url: "#{site_url}/#{I18n.locale}/courses/#{course.slug}"
    }
    data.to_json
  end

  # /glossary — one DefinedTermSet over every profession's abbreviations, so
  # each расшифровка is machine-readable for the long-tail «X расшифровка» SERP.
  def glossary_json_ld(groups)
    data = {
      "@context": "https://schema.org",
      "@type": "DefinedTermSet",
      name: I18n.t("glossary.title"),
      url: "#{site_url}/#{I18n.locale}/glossary",
      inLanguage: I18n.locale.to_s,
      hasDefinedTerm: groups.flat_map do |_path, terms|
        terms.map { |term| { "@type": "DefinedTerm", name: term.abbr, description: term.full } }
      end
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
