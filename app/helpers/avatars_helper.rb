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

  def avatar_tag(name, title: name)
    content_tag :span, avatar_initials(name),
      class: "avatar",
      style: "--avatar-hue: var(#{avatar_hue_token(name)})",
      title: title,
      aria: { hidden: true }
  end
end
