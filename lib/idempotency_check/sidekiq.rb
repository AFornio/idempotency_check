# frozen_string_literal: true

require_relative '../idempotency_check'
require 'sidekiq'
require 'sidekiq/test_api' # for Sidekiq::Testing.server_middleware, used under Sidekiq::Testing.inline!

module IdempotencyCheck
  # Accumulates every job actually performed (via Sidekiq::Testing.inline! or
  # a real worker process) for the lifetime of the process, by adding a
  # server middleware. Sidekiq has no ActiveSupport::Notifications-style hook
  # of its own, so we install our own.
  module SidekiqPerformTracker
    @performed = []

    class << self
      attr_reader :performed
    end

    def self.record(job_class, args)
      @performed << [job_class, args]
    end

    def self.reset!
      @performed = []
    end
  end

  class SidekiqServerTracker
    def call(_job_instance, msg, _queue)
      SidekiqPerformTracker.record(msg['class'], msg['args'])
      yield
    end
  end

  # Snapshots Sidekiq job activity so far (cumulative), broken down by job
  # class and arguments, covering both:
  #   - enqueued jobs (perform_async), via Sidekiq::Testing.fake!'s global
  #     Sidekiq::Queues registry (no middleware needed, Sidekiq tracks this
  #     itself)
  #   - performed jobs (perform_async under Sidekiq::Testing.inline!, or a
  #     real worker), via SidekiqServerTracker
  class SidekiqSnapshot
    def self.take
      {
        enqueued: Sidekiq::Queues.jobs_by_class.flat_map do |klass, jobs|
          jobs.map { |job| [klass, job['args']] }
        end,
        performed: SidekiqPerformTracker.performed.dup
      }
    end

    def self.reset!
      Sidekiq::Queues.clear_all
      SidekiqPerformTracker.reset!
    end
  end

  # Real worker process (production).
  Sidekiq.default_configuration.server_middleware do |chain|
    chain.add SidekiqServerTracker
  end

  # Sidekiq::Testing.inline! uses its own separate middleware chain.
  Sidekiq::Testing.server_middleware do |chain|
    chain.add SidekiqServerTracker
  end

  register_snapshot_source(:sidekiq, SidekiqSnapshot)
end
