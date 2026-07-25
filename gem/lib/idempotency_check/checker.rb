module IdempotencyCheck
  class Checker
    RUNS = 3
    TIMESTAMP_COLUMNS = %w[created_at updated_at].freeze

    @extra_snapshot_sources = []

    class << self
      attr_reader :extra_snapshot_sources
    end

    # Lets optional integrations (e.g. idempotency_check/sidekiq) plug in
    # their own snapshot source without the core Checker knowing about them.
    def self.register_snapshot_source(source)
      @extra_snapshot_sources << source
    end

    def self.idempotent?(ignore_columns: [], ignore_timestamps: false, &block)
      effective_ignore_columns = ignore_columns + (ignore_timestamps ? TIMESTAMP_COLUMNS : [])

      snapshots = {
        table: [],
        row: [],
        mailer: [],
        job: [],
      }
      extra_snapshot_sources.each { |source| snapshots[source] = [] }
      http_calls = 0

      RUNS.times do
        http_calls += HttpTracker.track(&block)
        snapshots[:table] << TableSnapshot.take
        snapshots[:row] << RowSnapshot.take(ignore_columns: effective_ignore_columns)
        snapshots[:mailer] << MailerSnapshot.take
        snapshots[:job] << JobSnapshot.take
        extra_snapshot_sources.each { |source| snapshots[source] << source.take }
      end

      looks_idempotent = snapshots.values.all? { |list| list.uniq.size == 1 }

      return false unless looks_idempotent
      return :suspicious if http_calls.positive?

      true
    end
  end
end
