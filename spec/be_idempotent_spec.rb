# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'be_idempotent matcher' do
  it 'passes for a block that is idempotent' do
    expect { IdempotentJob.perform }.to be_idempotent
  end

  it 'fails for a block that is not idempotent' do
    expect do
      expect { NonIdempotentJob.perform }.to be_idempotent
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /produced different effects \(.*row.*\)/)
  end

  it 'accepts options, such as ignoring timestamp-only changes' do
    expect { TimestampOnlyChangeJob.perform }.to be_idempotent(ignore_timestamps: true)
  end
end
