# frozen_string_literal: true

require 'idempotency_check'
require 'rspec/expectations'

RSpec::Matchers.define :be_idempotent do |**opts|
  supports_block_expectations

  match do |block|
    @outcome = IdempotencyCheck.idempotent?(**opts, verbose: true, &block)
    @outcome[:result]
  end

  failure_message do
    if @outcome[:reason] == :suspicious_http
      "expected the block to be idempotent, but it made external HTTP calls we can't verify"
    else
      reasons = Array(@outcome[:reason]).join(', ')
      "expected the block to be idempotent, but running it again produced different effects (#{reasons})"
    end
  end
end
