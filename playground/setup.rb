require "active_record"
require "action_mailer"
require "active_job"
require "sidekiq"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

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
Sidekiq.testing!(:inline)
