# frozen_string_literal: true

require_relative '../idempotency_check'
require 'sidekiq'

# Opt-in Sidekiq support: require 'idempotency_check/sidekiq'.
module IdempotencyCheck
  # Snapshots the Sidekiq jobs enqueued so far (perform_async under
  # Sidekiq::Testing.fake!), by class and arguments. Jobs run inline aren't
  # tracked: their effects already show up in the other snapshots.
  class SidekiqSnapshot
    def self.available?
      return true if defined?(Sidekiq::Testing) && !Sidekiq::Testing.disabled?

      raise SetupError, "enable Sidekiq's fake or inline testing mode (or pass trust: [:sidekiq])"
    end

    def self.take
      Sidekiq::Queues.jobs_by_class.flat_map do |klass, jobs|
        jobs.map { |job| [klass, job['args']] }
      end
    end

    def self.reset!
      Sidekiq::Queues.clear_all
    end
  end

  register_snapshot_source(:sidekiq, SidekiqSnapshot)
end
