class ImmediateJob < ActiveJob::Base
  def perform; end
end

class SyncJob
  def self.perform
    User.find_or_create_by(email: "h@h.com")
    ImmediateJob.perform_now
  end
end

class HappySyncJob
  def self.perform
    user = User.find_or_create_by(email: "i@i.com")
    return if user.followed_up?

    ImmediateJob.perform_now
    user.update!(followed_up: true)
  end
end
