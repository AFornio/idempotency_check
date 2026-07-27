# frozen_string_literal: true

require 'net/http'

module IdempotencyCheck
  # Counts how many outbound HTTP requests happen inside a block, by
  # wrapping Net::HTTP#request. We can't verify idempotency of external
  # side effects, so this is only used to flag results as suspicious.
  class HttpTracker
    def self.track
      count = 0
      original = Net::HTTP.instance_method(:request)

      Net::HTTP.send(:define_method, :request) do |*args, &blk|
        count += 1
        original.bind(self).call(*args, &blk)
      end

      yield

      count
    ensure
      Net::HTTP.send(:define_method, :request, original) if original
    end
  end
end
