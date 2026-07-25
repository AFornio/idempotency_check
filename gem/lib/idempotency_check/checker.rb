module IdempotencyCheck
  class Checker
    RUNS = 3
    TIMESTAMP_COLUMNS = %w[created_at updated_at].freeze

    def self.idempotent?(ignore_columns: [], ignore_timestamps: false, &block)
      effective_ignore_columns = ignore_columns + (ignore_timestamps ? TIMESTAMP_COLUMNS : [])

      table_snapshots = []
      row_snapshots = []
      mailer_snapshots = []
      job_snapshots = []
      http_calls = 0

      RUNS.times do
        http_calls += HttpTracker.track(&block)
        table_snapshots << TableSnapshot.take
        row_snapshots << RowSnapshot.take(ignore_columns: effective_ignore_columns)
        mailer_snapshots << MailerSnapshot.take
        job_snapshots << JobSnapshot.take
      end

      db_looks_idempotent =
        table_snapshots.uniq.size == 1 &&
        row_snapshots.uniq.size == 1 &&
        mailer_snapshots.uniq.size == 1 &&
        job_snapshots.uniq.size == 1

      return false unless db_looks_idempotent
      return :suspicious if http_calls.positive?

      true
    end
  end
end
