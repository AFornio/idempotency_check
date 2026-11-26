# frozen_string_literal: true

module IdempotencyCheck
  # Snapshots how many mails have been delivered so far (cumulative since the
  # last reset!), using ActionMailer's :test delivery method.
  class MailerSnapshot
    def self.available?
      return false unless defined?(ActionMailer::Base)
      return true if ActionMailer::Base.delivery_method == :test

      raise SetupError, 'set ActionMailer::Base.delivery_method = :test (or pass trust: [:mailer])'
    end

    def self.take
      ActionMailer::Base.deliveries.size
    end

    def self.reset!
      ActionMailer::Base.deliveries.clear
    end
  end
end
