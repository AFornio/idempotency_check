# frozen_string_literal: true

require 'idempotency_check'
require 'minitest/assertions'

module Minitest
  # Reopened to add assert_idempotent/refute_idempotent.
  module Assertions
    def assert_idempotent(**opts, &block)
      outcome = IdempotencyCheck.idempotent?(**opts, verbose: true, &block)
      assert outcome[:result], idempotent_failure_message(outcome[:reason])
    end

    def refute_idempotent(**opts, &block)
      outcome = IdempotencyCheck.idempotent?(**opts, verbose: true, &block)
      refute outcome[:result], 'expected the block not to be idempotent, but it was'
    end

    private

    def idempotent_failure_message(reason)
      if reason == :suspicious_http
        "expected the block to be idempotent, but it made external HTTP calls we can't verify"
      else
        reasons = Array(reason).join(', ')
        "expected the block to be idempotent, but running it again produced different effects (#{reasons})"
      end
    end
  end
end
