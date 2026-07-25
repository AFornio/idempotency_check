module IdempotencyCheck
  # Counts INSERT/UPDATE/DELETE statements per table executed inside a block,
  # by subscribing to ActiveSupport::Notifications "sql.active_record".
  class SqlTracker
    def self.track(&block)
      new.track(&block)
    end

    def track
      counts = Hash.new(0)

      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        sql = event.payload[:sql].to_s

        operation = sql[/\A\s*(INSERT|UPDATE|DELETE)/i, 1]
        next unless operation

        table = sql[/\A\s*#{operation}\s+(?:INTO\s+)?["`]?(\w+)/i, 1]
        next unless table

        counts["#{operation.upcase} #{table}"] += 1
      end

      yield

      counts
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    end
  end
end
