module IdempotencyCheck
  # Snapshots how many mails have been delivered so far (cumulative), using
  # ActionMailer's :test delivery method. Requires the host app to set
  # config.action_mailer.delivery_method = :test.
  class MailerSnapshot
    def self.take
      ActionMailer::Base.deliveries.size
    end
  end
end
