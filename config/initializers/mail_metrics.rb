# Count every delivered email into MailMetrics (Solid Cache) for the dashboard's
# "mail is flowing" signal. The `deliver.action_mailer` event fires once per
# message, in whichever process actually sends it (a Solid Queue worker for
# deliver_later). Harmless everywhere: a no-op on the test null-store, in-process
# in development, persistent in production — so it's wired in every environment.
ActiveSupport::Notifications.subscribe("deliver.action_mailer") do
  MailMetrics.record_delivery
end
