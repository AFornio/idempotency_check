module IdempotencyCheck
  class Checker
    RUNS = 3
    TIMESTAMP_COLUMNS = %w[created_at updated_at].freeze

    @extra_snapshot_sources = {}

    class << self
      attr_reader :extra_snapshot_sources
    end

    # Lets optional integrations (e.g. idempotency_check/sidekiq) plug in
    # their own snapshot source without the core Checker knowing about them.
    # `name` is the symbol callers use to refer to this source via `trust:`.
    # If the source responds to reset!, it's called before each check so
    # cumulative trackers don't grow unbounded across an entire test suite.
    def self.register_snapshot_source(name, source)
      @extra_snapshot_sources[name] = source
    end

    def self.idempotent?(ignore_columns: [], ignore_timestamps: false, trust: [], verbose: false, &block)
      effective_ignore_columns = ignore_columns + (ignore_timestamps ? TIMESTAMP_COLUMNS : [])
      trusted = Array(trust)

      MailerSnapshot.reset!
      ActiveJobSnapshot.reset!
      extra_snapshot_sources.each_value { |source| source.reset! if source.respond_to?(:reset!) }

      snapshots = {
        table: [],
        row: [],
        mailer: [],
        active_job: [],
      }
      extra_snapshot_sources.each_key { |name| snapshots[name] = [] }
      http_calls = 0

      RUNS.times do
        http_calls += HttpTracker.track(&block)
        snapshots[:table] << TableSnapshot.take
        snapshots[:row] << RowSnapshot.take(ignore_columns: effective_ignore_columns)
        snapshots[:mailer] << MailerSnapshot.take
        snapshots[:active_job] << ActiveJobSnapshot.take
        extra_snapshot_sources.each { |name, source| snapshots[name] << source.take }
      end

      changed_sources = snapshots
        .reject { |name, _| trusted.include?(name) }
        .select { |_, list| list.uniq.size > 1 }
        .keys

      suspicious_http = http_calls.positive? && !trusted.include?(:http)

      result = changed_sources.empty? && !suspicious_http

      return result unless verbose

      reason =
        if changed_sources.any?
          changed_sources
        elsif suspicious_http
          :suspicious_http
        else
          :ok
        end

      { result:, reason: }
    end
  end
end
