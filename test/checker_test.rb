# frozen_string_literal: true

require 'test_helper'

class CheckerTest < Minitest::Test
  def test_find_or_create_by_is_idempotent
    assert(IdempotencyCheck.idempotent? { IdempotentJob.perform })
  end

  def test_unconditional_create_is_not_idempotent
    refute(IdempotencyCheck.idempotent? { NonIdempotentJob.perform })
  end

  def test_verbose_reports_ok_reason_when_idempotent
    result = IdempotencyCheck.idempotent?(verbose: true) { IdempotentJob.perform }
    assert_equal({ result: true, reason: :ok }, result)
  end

  def test_verbose_reports_which_source_changed_when_not_idempotent
    result = IdempotencyCheck.idempotent?(verbose: true) { NonIdempotentJob.perform }
    assert_equal false, result[:result]
    assert_includes result[:reason], :row
  end

  def test_timestamp_only_changes_fail_strict_by_default
    refute(IdempotencyCheck.idempotent? { TimestampOnlyChangeJob.perform })
  end

  def test_ignore_timestamps_ignores_timestamp_only_changes
    assert IdempotencyCheck.idempotent?(ignore_timestamps: true) { TimestampOnlyChangeJob.perform }
  end
end
