# frozen_string_literal: true

class IdempotentJob
  def self.perform
    User.find_or_create_by(email: 'idempotent@example.com')
  end
end

class NonIdempotentJob
  def self.perform
    User.create!(email: 'non_idempotent@example.com')
  end
end

class TimestampOnlyChangeJob
  def self.perform
    user = User.find_or_create_by(email: 'timestamp_only@example.com')
    user.touch # bumps updated_at even though no business data changes
  end
end

class NotifierMailer < ActionMailer::Base
  def welcome
    mail(from: 'noreply@example.com', to: 'someone@example.com', subject: 'welcome', body: 'hi')
  end
end

class UnguardedMailerJob
  def self.perform
    User.find_or_create_by(email: 'mailer@example.com')
    NotifierMailer.welcome.deliver_now
  end
end

class GuardedMailerJob
  def self.perform
    user = User.find_or_create_by(email: 'guarded_mailer@example.com')
    return if user.notified?

    NotifierMailer.welcome.deliver_now
    user.update!(notified: true)
  end
end

class FollowUpJob < ActiveJob::Base
  def perform(*); end
end

class UnguardedEnqueueJob
  def self.perform
    User.find_or_create_by(email: 'enqueue@example.com')
    FollowUpJob.perform_later
  end
end

class GuardedEnqueueJob
  def self.perform
    user = User.find_or_create_by(email: 'guarded_enqueue@example.com')
    return if user.followed_up?

    FollowUpJob.perform_later
    user.update!(followed_up: true)
  end
end

class ImmediateJob < ActiveJob::Base
  def perform(*); end
end

class UnguardedSyncJob
  def self.perform
    User.find_or_create_by(email: 'sync@example.com')
    ImmediateJob.perform_now
  end
end

# update_column bypasses validations AND callbacks entirely (unlike
# save/update!/touch), and does not bump updated_at on its own.
class UpdateColumnSameValueJob
  def self.perform
    user = User.find_or_create_by(email: 'update_column_same@example.com')
    user.update_column(:visits, 1)
  end
end

class UpdateColumnChangingValueJob
  def self.perform
    user = User.find_or_create_by(email: 'update_column_changing@example.com')
    user.update_column(:visits, user.visits + 1)
  end
end

require 'net/http'

# Fakes the network layer so this test suite never makes a real outbound
# HTTP call. Overriding at the class level (not as a singleton method on one
# instance) means HttpTracker's own class-level override still takes effect
# on top of this fake.
class Net::HTTP
  def request(*, **)
    Net::HTTPResponse.new('1.1', '200', 'OK')
  end
end

class ExternalApiJob
  def self.perform
    user = User.find_or_create_by(email: 'api@example.com')
    Net::HTTP.new('example.test', 80).request(Net::HTTP::Get.new('/notify'))
    user
  end
end
