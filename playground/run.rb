require_relative "../gem/lib/idempotency_check"
require_relative "../gem/lib/idempotency_check/sidekiq"
require_relative "setup"
require_relative "sidekiq_jobs"
require_relative "happy_job"
require_relative "bad_job"
require_relative "increment_job"
require_relative "api_job"
require_relative "mailer_job"
require_relative "enqueue_job"
require_relative "upsert_job"
require_relative "sync_job"
require_relative "job_args_cases"
require_relative "random_update_job"

puts "HappyJob idempotent?     #{IdempotencyCheck.idempotent? { HappyJob.perform }}"
puts "BadJob idempotent?       #{IdempotencyCheck.idempotent? { BadJob.perform }}"
puts "IncrementJob idempotent? #{IdempotencyCheck.idempotent? { IncrementJob.perform }}"
puts "ApiJob idempotent?       #{IdempotencyCheck.idempotent? { ApiJob.perform }}"
puts "MailerJob idempotent?       #{IdempotencyCheck.idempotent? { MailerJob.perform }}"
puts "HappyMailerJob idempotent?  #{IdempotencyCheck.idempotent? { HappyMailerJob.perform }}"
puts "EnqueueJob idempotent?      #{IdempotencyCheck.idempotent? { EnqueueJob.perform }}"
puts "HappyEnqueueJob idempotent? #{IdempotencyCheck.idempotent? { HappyEnqueueJob.perform }}"
puts "UpsertJob idempotent? (strict)           #{IdempotencyCheck.idempotent? { UpsertJob.perform }}"
puts "UpsertJob idempotent? (ignore_timestamps) #{IdempotencyCheck.idempotent?(ignore_timestamps: true) { UpsertJob.perform }}"
puts "SyncJob idempotent?      #{IdempotencyCheck.idempotent? { SyncJob.perform }}"
puts "HappySyncJob idempotent? #{IdempotencyCheck.idempotent? { HappySyncJob.perform }}"

puts "DuplicateArgsJob idempotent? (mismos args cada vez)     #{IdempotencyCheck.idempotent? { DuplicateArgsJob.perform }}"
puts "DifferentArgsJob idempotent? (args distintos cada vez)  #{IdempotencyCheck.idempotent? { DifferentArgsJob.perform }}"

# Caso C: mismo job, mismo bloque de código, pero literales de args distintos
# en dos checks independientes — confirmar que no se confunden entre sí.
puts "FollowUpJob.perform_later(1, 2) idempotent? #{IdempotencyCheck.idempotent? { FollowUpJob.perform_later(1, 2) }}"
puts "FollowUpJob.perform_later(3, 4) idempotent? #{IdempotencyCheck.idempotent? { FollowUpJob.perform_later(3, 4) }}"

# No es un job, es un bloque cualquiera de código — la gema no distingue.
user = User.find_or_create_by(email: "m@m.com")
puts "user.update! idempotent? #{IdempotencyCheck.idempotent? { user.update!(email: "m@m.com") }}"
puts "user.increment! idempotent? #{IdempotencyCheck.idempotent? { user.increment!(:visits) }}"

other_user = User.find_or_create_by(email: "n@n.com")
puts "user.update!(email: 'hola') idempotent? #{IdempotencyCheck.idempotent? { other_user.update!(email: "hola") }}"

puts "RandomUpdateJob idempotent? (strict)           #{IdempotencyCheck.idempotent? { RandomUpdateJob.perform }}"
puts "RandomUpdateJob idempotent? (ignore_timestamps) #{IdempotencyCheck.idempotent?(ignore_timestamps: true) { RandomUpdateJob.perform }}"

puts "BadSidekiqJob idempotent?   #{IdempotencyCheck.idempotent? { BadSidekiqJob.perform }}"
puts "HappySidekiqJob idempotent? #{IdempotencyCheck.idempotent? { HappySidekiqJob.perform }}"

puts "SidekiqDuplicateArgsJob idempotent? (mismos args cada vez)    #{IdempotencyCheck.idempotent? { SidekiqDuplicateArgsJob.perform }}"
puts "SidekiqDifferentArgsJob idempotent? (args distintos cada vez) #{IdempotencyCheck.idempotent? { SidekiqDifferentArgsJob.perform }}"

# Mismo worker, literales de args distintos, dos checks independientes.
puts "NotifyWorker.perform_async(1, 2) idempotent? #{IdempotencyCheck.idempotent? { NotifyWorker.perform_async(1, 2) }}"
puts "NotifyWorker.perform_async(3, 4) idempotent? #{IdempotencyCheck.idempotent? { NotifyWorker.perform_async(3, 4) }}"
