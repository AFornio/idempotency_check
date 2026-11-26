# frozen_string_literal: true

module IdempotencyCheck
  # Raised when a side effect can't be observed with the current setup (e.g. a
  # queue adapter other than :test), so a result would be a guess.
  class SetupError < StandardError; end

  # Runs the block RUNS times and compares the snapshots taken after each run.
  class Checker
    RUNS = 3
    TIMESTAMP_COLUMNS = %w[created_at updated_at].freeze

    @snapshot_sources = { mailer: MailerSnapshot, active_job: ActiveJobSnapshot }

    class << self
      # A source responds to available? (false when its library isn't loaded,
      # raises SetupError when it's loaded but can't be observed), reset! and
      # take. `name` is what callers pass to `trust:` to skip it.
      def register_snapshot_source(name, source)
        @snapshot_sources[name] = source
      end

      def idempotent?(ignore_columns: [], ignore_timestamps: false, trust: [], verbose: false, &)
        trusted = Array(trust)
        ignored = ignore_columns + (ignore_timestamps ? TIMESTAMP_COLUMNS : [])
        snapshots, http_calls = run(sources(trusted), ignored, &)

        changed = changed_sources(snapshots.except(*trusted))
        suspicious_http = http_calls.positive? && !trusted.include?(:http)
        result = changed.empty? && !suspicious_http

        verbose ? { result: result, reason: reason(changed, suspicious_http) } : result
      end

      private

      def sources(trusted)
        @snapshot_sources.reject { |name, source| trusted.include?(name) || !source.available? }
                         .each_value(&:reset!)
      end

      def run(sources, ignored, &block)
        snapshots = Hash.new { |hash, name| hash[name] = [] }
        http_calls = 0
        # Accumulated across runs: a run that writes a new table is itself a
        # sign the block isn't settling down.
        tables = []

        RUNS.times do
          http_calls += HttpTracker.track { tables |= SqlTracker.track(&block) }
          take_snapshots(snapshots, sources, tables, ignored)
        end

        [snapshots, http_calls]
      end

      def take_snapshots(snapshots, sources, tables, ignored)
        snapshots[:table] << TableSnapshot.take(tables: tables)
        snapshots[:row] << RowSnapshot.take(tables: tables, ignore_columns: ignored)
        sources.each { |name, source| snapshots[name] << source.take }
      end

      def changed_sources(snapshots)
        snapshots.select { |_, list| list.uniq.size > 1 }.keys
      end

      def reason(changed, suspicious_http)
        return changed if changed.any?

        suspicious_http ? :suspicious_http : :ok
      end
    end
  end
end
