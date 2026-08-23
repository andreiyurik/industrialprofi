module AvatarsHelper
  # Generated initials avatars — no uploads, no storage, no moderation. The
  # background hue is picked from the OKLCH accent primitives in colors.css
  # (never a raw colour) and is stable per name, so the same person always
  # looks the same. This is the Basecamp/HEY pattern, server-rendered.
  AVATAR_HUES = %w[--lch-blue --lch-teal --lch-purple --lch-green --lch-yellow --lch-red].freeze

  def avatar_initials(name)
    parts = name.to_s.strip.split(/\s+/).reject(&:blank?)
    return "?" if parts.empty?

    parts.first(2).map { |part| part.chars.first }.join.upcase
  end

  def avatar_hue_token(name)
    AVATAR_HUES[name.to_s.sum % AVATAR_HUES.size]
  end

  # Takes the user, not the name: a chosen preset glyph (Avatar) wins, the
  # generated initials remain the default for everyone who never picked one.
  def avatar_tag(user, title: user.name)
    if user.shows_photo?
      image_tag rails_storage_proxy_path(user.photo), class: "avatar avatar--photo",
        alt: "", title: title, width: User::Photo::SIZE, height: User::Photo::SIZE, aria: { hidden: true }
    elsif (preset = Avatar[user.avatar_token])
      content_tag :span, icon_tag(preset[:icon]),
        class: "avatar avatar--glyph",
        style: "--avatar-hue: var(#{preset[:hue]})",
        title: title,
        aria: { hidden: true }
    else
      content_tag :span, avatar_initials(user.name),
        class: "avatar",
        style: "--avatar-hue: var(#{avatar_hue_token(user.name)})",
        title: title,
        aria: { hidden: true }
    end
  end
end
