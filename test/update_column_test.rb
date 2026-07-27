# frozen_string_literal: true

require 'test_helper'

class UpdateColumnTest < Minitest::Test
  def test_update_column_with_same_value_every_run_is_idempotent
    assert(IdempotencyCheck.idempotent? { UpdateColumnSameValueJob.perform })
  end

  def test_update_column_with_changing_value_is_not_idempotent
    refute(IdempotencyCheck.idempotent? { UpdateColumnChangingValueJob.perform })
  end
end
