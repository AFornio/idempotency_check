require "active_support/notifications"

module IdempotencyCheck
  # Accumulates every job actually performed (synchronously, e.g. via
  # perform_now) for the lifetime of the process, by subscribing to
  # ActiveJob's core "perform.active_job" notification. This fires
  # regardless of queue adapter, but with queue_adapter = :test it's the
  # only way to see synchronous performs, since perform_later jobs just
  # sit in the queue and never actually run.
  module JobPerformTracker
    @performed = []

    class << self
      attr_reader :performed
    end

    ActiveSupport::Notifications.subscribe("perform.active_job") do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      job = event.payload[:job]
      @performed << [job.class.name, job.arguments]
    end
  end
end
