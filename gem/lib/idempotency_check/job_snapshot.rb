module IdempotencyCheck
  # Snapshots job activity so far (cumulative), broken down by job class and
  # arguments so that swapping which job/args ran between runs is caught,
  # not just a raw count. Covers both:
  #   - enqueued jobs (perform_later), via ActiveJob's :test queue adapter
  #   - performed jobs (perform_now), via JobPerformTracker
  # Requires ActiveJob::Base.queue_adapter = :test in the host app.
  class JobSnapshot
    def self.take
      {
        enqueued: ActiveJob::Base.queue_adapter.enqueued_jobs.map { |job| [job[:job].name, job[:args]] },
        performed: JobPerformTracker.performed.dup,
      }
    end
  end
end
