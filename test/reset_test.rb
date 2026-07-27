# frozen_string_literal: true

require 'test_helper'

class ResetTest < Minitest::Test
  def test_cumulative_trackers_do_not_grow_across_independent_checks
    5.times { IdempotencyCheck.idempotent? { GuardedMailerJob.perform } }
    5.times { IdempotencyCheck.idempotent? { GuardedEnqueueJob.perform } }

    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_equal [], ActiveJob::Base.queue_adapter.enqueued_jobs
  end
end
