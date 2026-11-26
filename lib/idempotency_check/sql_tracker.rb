# frozen_string_literal: true

module IdempotencyCheck
  # Collects which tables received a write (INSERT/UPDATE/DELETE) inside a
  # block, by subscribing to ActiveSupport::Notifications "sql.active_record".
  #
  # This only narrows down which tables are worth snapshotting — it never
  # decides idempotency on its own. That matters: if the SQL parsing below
  # reports a table that wasn't really written to, the cost is one extra
  # table snapshotted, not a wrong answer.
  class SqlTracker
    IGNORED_TABLES = %w[schema_migrations ar_internal_metadata].freeze

    class << self
      def track(&)
        new.track(&)
      end
    end

    def track
      tables = []

      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        table = written_table(event.payload[:sql].to_s)
        tables << table if table
      end

      yield

      tables.uniq
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    end

    private

    def written_table(sql)
      operation = sql[/\A\s*(INSERT|UPDATE|DELETE)/i, 1]
      return unless operation

      table = sql[/\A\s*#{operation}\s+(?:INTO\s+|FROM\s+)?["`\[]?(\w+)/i, 1]
      return if table.nil? || IGNORED_TABLES.include?(table)

      table
    end
  end
end
