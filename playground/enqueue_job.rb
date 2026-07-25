class FollowUpJob < ActiveJob::Base
  def perform(*); end
end

class EnqueueJob
  def self.perform
    User.find_or_create_by(email: "d@d.com")
    FollowUpJob.perform_later
  end
end

class HappyEnqueueJob
  def self.perform
    user = User.find_or_create_by(email: "f@f.com")
    return if user.followed_up?

    FollowUpJob.perform_later
    user.update!(followed_up: true)
  end
end
