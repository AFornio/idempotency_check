# frozen_string_literal: true

module IdempotencyCheck
  # Snapshots job activity so far (cumulative since the last reset!), broken
  # down by job class and arguments so that swapping which job/args ran
  # between runs is caught, not just a raw count. Covers both:
  #   - enqueued jobs (perform_later), via ActiveJob's :test queue adapter
  #   - performed jobs (perform_now), via ActiveJobPerformTracker
  # Requires ActiveJob::Base.queue_adapter = :test in the host app.
  class ActiveJobSnapshot
    def self.take
      {
        enqueued: ActiveJob::Base.queue_adapter.enqueued_jobs.map { |job| [job[:job].name, job[:args]] },
        performed: ActiveJobPerformTracker.performed.dup
      }
    end

    def self.reset!
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      ActiveJobPerformTracker.reset!
    end
  end
end
