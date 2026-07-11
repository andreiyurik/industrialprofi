class EditorshipsMailer < ApplicationMailer
  # The trust-ladder handshake: someone was just handed direct edit rights to
  # one or more professions. A rare administrative notice, not a campaign —
  # so no unsubscribe, like a password reset.
  def granted(user, paths)
    @user = user
    @paths = paths

    mail to: user.email_address,
         subject: t("editorships_mailer.granted.subject", count: paths.size,
                    profession: paths.first.title)
  end
end
