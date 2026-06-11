# Email-based error monitoring (the whole setup: this line + ErrorSubscriber +
# ErrorMailer). Production only — in development errors show on screen, and the
# test suite raises them.
Rails.application.config.after_initialize do
  Rails.error.subscribe(ErrorSubscriber.new) if Rails.env.production?
end
