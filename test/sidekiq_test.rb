# frozen_string_literal: true

require 'test_helper'
require 'idempotency_check/sidekiq'

Sidekiq.testing!(:fake)

class NotifyWorker
  include Sidekiq::Job

  def perform(*); end
end

class UnguardedSidekiqJob
  def self.perform
    User.find_or_create_by(email: 'sidekiq@example.com')
    NotifyWorker.perform_async(1, 2)
  end
end

class GuardedSidekiqJob
  def self.perform
    user = User.find_or_create_by(email: 'guarded_sidekiq@example.com')
    return if user.followed_up?

    NotifyWorker.perform_async(1, 2)
    user.update!(followed_up: true)
  end
end

class SidekiqTest < Minitest::Test
  def test_unguarded_perform_async_is_not_idempotent
    refute(IdempotencyCheck.idempotent? { UnguardedSidekiqJob.perform })
  end

  def test_inline_perform_async_of_a_no_op_worker_is_idempotent
    Sidekiq.testing!(:inline) do
      assert(IdempotencyCheck.idempotent? { NotifyWorker.perform_async(1, 2) })
    end
  end

  def test_guarded_perform_async_is_idempotent
    assert(IdempotencyCheck.idempotent? { GuardedSidekiqJob.perform })
  end
end

class SidekiqSetupTest < Minitest::Test
  def test_disabled_testing_mode_raises_a_clear_error
    Sidekiq.testing!(:disable) do
      error = assert_raises(IdempotencyCheck::SetupError) { IdempotencyCheck.idempotent? { 1 } }
      assert_match(/testing mode/, error.message)
    end
  end
end
