# frozen_string_literal: true

require 'test_helper'

class ActiveJobTest < Minitest::Test
  def test_unguarded_enqueue_is_not_idempotent
    refute(IdempotencyCheck.idempotent? { UnguardedEnqueueJob.perform })
  end

  def test_guarded_enqueue_is_idempotent
    assert(IdempotencyCheck.idempotent? { GuardedEnqueueJob.perform })
  end

  def test_top_level_perform_now_of_an_idempotent_job_is_idempotent
    assert(IdempotencyCheck.idempotent? { RealIdempotentJob.perform_now })
  end

  def test_top_level_perform_now_of_a_non_idempotent_job_is_not_idempotent
    refute(IdempotencyCheck.idempotent? { RealNonIdempotentJob.perform_now })
  end

  def test_same_args_enqueued_every_run_is_not_idempotent
    refute(IdempotencyCheck.idempotent? { FollowUpJob.perform_later(1, 2) })
  end

  def test_independent_checks_with_different_args_do_not_cross_contaminate
    refute(IdempotencyCheck.idempotent? { FollowUpJob.perform_later(1, 2) })
    refute(IdempotencyCheck.idempotent? { FollowUpJob.perform_later(3, 4) })
  end
end
