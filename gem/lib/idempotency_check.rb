require_relative "idempotency_check/version"
require_relative "idempotency_check/sql_tracker"
require_relative "idempotency_check/table_snapshot"
require_relative "idempotency_check/row_snapshot"
require_relative "idempotency_check/http_tracker"
require_relative "idempotency_check/mailer_snapshot"
require_relative "idempotency_check/active_job_perform_tracker"
require_relative "idempotency_check/active_job_snapshot"
require_relative "idempotency_check/checker"

module IdempotencyCheck
  def self.idempotent?(**opts, &block)
    Checker.idempotent?(**opts, &block)
  end

  def self.register_snapshot_source(name, source)
    Checker.register_snapshot_source(name, source)
  end

  private_constant :Checker
end
