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

class InteractionTest < Minitest::Test
  def test_unguarded_interaction_is_not_idempotent
    refute IdempotencyCheck.idempotent? { UnguardedCreateUserInteraction.run!(email: "interaction@example.com") }
  end

  def test_guarded_interaction_is_idempotent
    assert IdempotencyCheck.idempotent? { GuardedCreateUserInteraction.run!(email: "guarded_interaction@example.com") }
  end
end
