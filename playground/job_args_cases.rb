# Case A: enqueues another job with the SAME params every run (no guard) —
# still non-idempotent, since the job gets duplicated regardless of args.
class DuplicateArgsJob
  def self.perform
    User.find_or_create_by(email: "k@k.com")
    FollowUpJob.perform_later(1, 2)
  end
end

# Case B: enqueues another job with DIFFERENT params every run (args drift
# based on mutable state) — non-idempotent, and the drift itself is visible
# in the snapshot content, not just the count.
class DifferentArgsJob
  def self.perform
    user = User.find_or_create_by(email: "l@l.com")
    FollowUpJob.perform_later(user.visits)
    user.increment!(:visits)
  end
end
