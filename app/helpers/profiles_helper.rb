module ProfilesHelper
  # A person's name, linked to their public profile when they have one — the
  # same rule everywhere a face or a name appears (hub header, popover, maps).
  def person_link(user, css: nil)
    if user.profile?
      link_to user.name, profile_path(user.handle), class: css
    else
      tag.span user.name, class: css
    end
  end

  # «А, Б и В» for already-rendered links — to_sentence would escape them back
  # to text; this keeps each part safe and reads the locale's «и»
  # (support.array, the same keys to_sentence uses elsewhere).
  def people_sentence(parts)
    return safe_join(parts) if parts.size < 2

    connector = t(parts.size == 2 ? "support.array.two_words_connector" : "support.array.last_word_connector")
    safe_join([ safe_join(parts[0..-2], t("support.array.words_connector")), parts.last ], connector)
  end

  # A face that opens the profile when there is one; a plain face otherwise.
  def person_avatar(user)
    if user.profile?
      link_to avatar_tag(user), profile_path(user.handle), class: "avatar-link", title: user.name
    else
      avatar_tag(user)
    end
  end
end
