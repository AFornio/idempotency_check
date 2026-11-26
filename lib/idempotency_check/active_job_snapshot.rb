# frozen_string_literal: true

module IdempotencyCheck
  # Snapshots the jobs enqueued so far (perform_later), cumulative since the
  # last reset!, by class and arguments so swapping which job/args ran between
  # runs is caught, not just a raw count. Jobs performed synchronously aren't
  # tracked: their effects already show up in the other snapshots.
  class ActiveJobSnapshot
    def self.available?
      return false unless defined?(ActiveJob::Base)
      return true if ActiveJob::Base.queue_adapter.respond_to?(:enqueued_jobs)

      raise SetupError, 'set ActiveJob::Base.queue_adapter = :test (or pass trust: [:active_job])'
    end

    def self.take
      ActiveJob::Base.queue_adapter.enqueued_jobs.map { |job| [job[:job].name, job[:args]] }
    end

    def self.reset!
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    end
  end
end
