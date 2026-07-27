require "test_helper"
require "active_interaction"

class UnguardedCreateUserInteraction < ActiveInteraction::Base
  string :email

  def execute
    User.create!(email:)
  end
end

class GuardedCreateUserInteraction < ActiveInteraction::Base
  string :email

  def execute
    User.find_or_create_by(email:)
  end
end

# Composes another interaction internally (the "organizer" pattern) without
# a guard — welcomes the user by mail every single run.
class UnguardedOnboardUserInteraction < ActiveInteraction::Base
  string :email

  def execute
    user = compose(GuardedCreateUserInteraction, email:)
    NotifierMailer.welcome.deliver_now
    user
  end
end

# Same composition, but guarded so the mail only goes out once.
class GuardedOnboardUserInteraction < ActiveInteraction::Base
  string :email

  def execute
    user = compose(GuardedCreateUserInteraction, email:)
    return user if user.notified?

    NotifierMailer.welcome.deliver_now
    user.update!(notified: true)
    user
  end
end

# ActiveInteraction's non-bang .run returns an Outcome instead of raising;
# an invalid outcome shouldn't have run `execute` at all.
class ValidatedCreateUserInteraction < ActiveInteraction::Base
  string :email

  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }

  def execute
    User.find_or_create_by(email:)
  end
end

class InteractionTest < Minitest::Test
  def test_unguarded_interaction_is_not_idempotent
    refute IdempotencyCheck.idempotent? { UnguardedCreateUserInteraction.run!(email: "interaction@example.com") }
  end

  def test_guarded_interaction_is_idempotent
    assert IdempotencyCheck.idempotent? { GuardedCreateUserInteraction.run!(email: "guarded_interaction@example.com") }
  end

  def test_unguarded_organizer_is_not_idempotent
    refute IdempotencyCheck.idempotent? { UnguardedOnboardUserInteraction.run!(email: "onboard@example.com") }
  end

  def test_guarded_organizer_is_idempotent
    assert IdempotencyCheck.idempotent? { GuardedOnboardUserInteraction.run!(email: "guarded_onboard@example.com") }
  end

  def test_invalid_input_never_touches_the_db_and_is_trivially_idempotent
    assert IdempotencyCheck.idempotent? { ValidatedCreateUserInteraction.run(email: "not-an-email") }
  end
end
