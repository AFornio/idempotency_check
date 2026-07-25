class NotifyWorker
  include Sidekiq::Job

  def perform(*); end
end

# Bad: enqueues/performs NotifyWorker every time, no guard.
class BadSidekiqJob
  def self.perform
    User.find_or_create_by(email: "p@p.com")
    NotifyWorker.perform_async(1, 2)
  end
end

# Happy: only performs NotifyWorker once, guarded by a flag.
class HappySidekiqJob
  def self.perform
    user = User.find_or_create_by(email: "q@q.com")
    return if user.followed_up?

    NotifyWorker.perform_async(1, 2)
    user.update!(followed_up: true)
  end
end
