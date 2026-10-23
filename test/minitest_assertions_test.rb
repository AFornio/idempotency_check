# frozen_string_literal: true

require 'test_helper'
require 'idempotency_check/minitest'

class MinitestAssertionsTest < Minitest::Test
  def test_assert_idempotent_passes_for_idempotent_block
    assert_idempotent { IdempotentJob.perform }
  end

  def test_assert_idempotent_fails_for_non_idempotent_block
    error = assert_raises(Minitest::Assertion) do
      assert_idempotent { NonIdempotentJob.perform }
    end
    assert_match(/produced different effects \(.*row.*\)/, error.message)
  end

  def test_refute_idempotent_passes_for_non_idempotent_block
    refute_idempotent { NonIdempotentJob.perform }
  end

  def test_refute_idempotent_fails_for_idempotent_block
    assert_raises(Minitest::Assertion) do
      refute_idempotent { IdempotentJob.perform }
    end
  end
end
