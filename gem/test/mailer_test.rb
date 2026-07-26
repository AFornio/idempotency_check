require "test_helper"

class MailerTest < Minitest::Test
  def test_unguarded_mailer_send_is_not_idempotent
    refute IdempotencyCheck.idempotent? { UnguardedMailerJob.perform }
  end

  def test_guarded_mailer_send_is_idempotent
    assert IdempotencyCheck.idempotent? { GuardedMailerJob.perform }
  end
end
