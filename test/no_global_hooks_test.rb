# frozen_string_literal: true

require 'test_helper'

class NoGlobalHooksTest < Minitest::Test
  def test_requiring_the_gem_leaves_no_job_listener_behind
    refute ActiveSupport::Notifications.notifier.listening?('perform.active_job')
  end

  def test_no_sql_listener_is_left_after_a_check
    before = sql_listeners
    IdempotencyCheck.idempotent? { User.find_or_create_by(email: 'hooks@example.com') }

    assert_equal before, sql_listeners
  end

  private

  def sql_listeners
    ActiveSupport::Notifications.notifier.listeners_for('sql.active_record').size
  end
end
