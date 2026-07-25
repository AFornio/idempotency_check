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

# Enqueues/performs NotifyWorker with the SAME args every run (no guard) —
# still non-idempotent, since the job gets duplicated regardless of args.
class SidekiqDuplicateArgsJob
  def self.perform
    User.find_or_create_by(email: "r@r.com")
    NotifyWorker.perform_async(1, 2)
  end
end

# Enqueues/performs NotifyWorker with DIFFERENT args every run (drift based
# on mutable state) — non-idempotent, visible in content, not just count.
class SidekiqDifferentArgsJob
  def self.perform
    user = User.find_or_create_by(email: "s@s.com")
    NotifyWorker.perform_async(user.visits)
    user.increment!(:visits)
  end
end
