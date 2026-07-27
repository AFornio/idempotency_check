# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'active_record'
require 'action_mailer'
require 'active_job'

require 'idempotency_check'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = nil

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :email
    t.integer :visits, default: 0
    t.boolean :notified, default: false
    t.boolean :followed_up, default: false
    t.timestamps
  end
end

class User < ActiveRecord::Base
end

ActionMailer::Base.delivery_method = :test
ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = nil

Dir[File.expand_path('support/*.rb', __dir__)].sort.each { |f| require f }
