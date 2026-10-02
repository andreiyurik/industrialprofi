module Admin::NavHelper
  def admin_nav_link(label, path, icon:, current: false, &block)
    link_to path, class: "admin-nav__link", aria: { current: ("page" if current) } do
      safe_join([ icon_tag(icon), tag.span(label, class: "admin-nav__label"), (capture(&block) if block) ])
    end
  end

  # Red waits on you, amber is something broken, blue is news to glance at.
  def admin_nav_count(count, tone: nil, title: nil)
    return unless count.positive?

    tag.span count, class: class_names("admin-nav__count", "admin-nav__count--#{tone}" => tone), title: title
  end
end
