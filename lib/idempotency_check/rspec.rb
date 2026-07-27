# frozen_string_literal: true

require 'idempotency_check'
require 'rspec/expectations'

RSpec::Matchers.define :be_idempotent do |**opts|
  supports_block_expectations

  match do |block|
    @result = IdempotencyCheck.idempotent?(**opts, &block)
    @result == true
  end

  failure_message do
    if @result == :suspicious
      "expected the block to be idempotent, but it made external HTTP calls we can't verify"
    else
      'expected the block to be idempotent, but running it again produced different effects'
    end
  end
end
