# frozen_string_literal: true

require 'test_helper'
require 'open3'

class SetupTest < Minitest::Test
  def test_non_test_queue_adapter_raises_a_clear_error
    with_queue_adapter(:async) do
      error = assert_raises(IdempotencyCheck::SetupError) { IdempotencyCheck.idempotent? { 1 } }
      assert_match(/queue_adapter = :test/, error.message)
    end
  end

  def test_trusting_active_job_skips_the_adapter_requirement
    with_queue_adapter(:async) do
      assert(IdempotencyCheck.idempotent?(trust: [:active_job]) { 1 })
    end
  end

  def test_non_test_delivery_method_raises_a_clear_error
    original = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :smtp
    error = assert_raises(IdempotencyCheck::SetupError) { IdempotencyCheck.idempotent? { 1 } }
    assert_match(/delivery_method = :test/, error.message)
  ensure
    ActionMailer::Base.delivery_method = original
  end

  def test_works_without_action_mailer_or_active_job_loaded
    script = <<~RUBY
      require 'active_record'
      require 'idempotency_check'
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
      ActiveRecord::Schema.verbose = false
      ActiveRecord::Schema.define { create_table(:items) { |t| t.string :name } }
      item = Class.new(ActiveRecord::Base) { self.table_name = 'items' }
      print IdempotencyCheck.idempotent? { item.find_or_create_by(name: 'a') }
      print IdempotencyCheck.idempotent? { item.create!(name: 'b') }
    RUBY
    out, err, status = Open3.capture3(RbConfig.ruby, '-Ilib', '-e', script)

    assert status.success?, err
    assert_equal 'truefalse', out
  end

  private

  def with_queue_adapter(adapter)
    original = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = adapter
    yield
  ensure
    ActiveJob::Base.queue_adapter = original
  end
end
