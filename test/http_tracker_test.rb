# frozen_string_literal: true

require 'test_helper'

class HttpTrackerTest < Minitest::Test
  def test_http_call_is_not_idempotent_by_default
    refute(IdempotencyCheck.idempotent? { ExternalApiJob.perform })
  end

  def test_trust_http_suppresses_the_unverifiable_http_call
    assert IdempotencyCheck.idempotent?(trust: [:http]) { ExternalApiJob.perform }
  end

  def test_verbose_reports_suspicious_http_reason
    result = IdempotencyCheck.idempotent?(verbose: true) { ExternalApiJob.perform }
    assert_equal({ result: false, reason: :suspicious_http }, result)
  end
end
