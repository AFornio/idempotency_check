# idempotency_check

Detects whether a job — or any block of Ruby code — is idempotent, by running
it multiple times and comparing the side effects it produces.

It works by running your block 3 times and comparing, between runs:

- database row counts and content (via ActiveRecord)
- ActionMailer deliveries
- ActiveJob activity (`perform_later` and `perform_now`), broken down by job
  class and arguments
- optionally, Sidekiq activity (`perform_async`), if you opt in
- outbound HTTP calls, which can't be verified, so they're flagged instead of
  assumed safe

It has **no runtime dependencies**. It works on any block of code, not only
jobs — `IdempotencyCheck.idempotent? { user.update!(...) }` works the same way
as it does for a job's `perform`.

## Installation

```ruby
gem "idempotency_check"
```

## Usage

```ruby
require "idempotency_check"

IdempotencyCheck.idempotent? { MyJob.perform_now(user_id) }
# => true, false
```

Returns `true` only when running the block again produces no additional
effect. Any unconfirmed situation (see "HTTP calls" below) is treated as
`false` by default — the safe assumption is "not confirmed idempotent",
never a false positive.

### Ignoring timestamp-only changes

A job that calls `.touch`/`.save` on every run bumps `updated_at` even if
nothing else changed. By default that counts as non-idempotent (strict); opt
out with:

```ruby
IdempotencyCheck.idempotent?(ignore_timestamps: true) { MyJob.perform_now }
# or, to ignore other specific columns:
IdempotencyCheck.idempotent?(ignore_columns: ["last_checked_at"]) { MyJob.perform_now }
```

### HTTP calls

Outbound HTTP calls can't be verified — the gem doesn't know whether the
external service is itself idempotent. By default, any HTTP call during the
run makes the result `false` (unconfirmed = not safe to assume). If you've
independently verified a particular source is safe (e.g. it calls your own
idempotent internal API), exclude it from the check:

```ruby
IdempotencyCheck.idempotent?(trust: [:http]) { MyJob.perform_now }
```

`trust:` accepts any of the sources the checker tracks: `:table`, `:row`,
`:mailer`, `:active_job`, `:http`, and (if loaded) `:sidekiq`.

### Getting a reason, not just true/false

```ruby
IdempotencyCheck.idempotent?(verbose: true) { MyJob.perform_now }
# => { result: true, reason: :ok }
# => { result: false, reason: [:row] }              # which source(s) changed
# => { result: false, reason: :suspicious_http }     # DB looked fine, but there was an unverified HTTP call
```

## Optional integrations

Neither of these are gemspec dependencies — they're only loaded (and only
need their gem installed) if you explicitly require them.

### RSpec

```ruby
require "idempotency_check/rspec"

expect { MyJob.perform_now(user_id) }.to be_idempotent
expect { MyJob.perform_now(user_id) }.to be_idempotent(trust: [:http])
```

### Sidekiq (native `include Sidekiq::Job` / `perform_async`)

ActiveJob is supported out of the box, even when Sidekiq is its queue
adapter. This is only needed for jobs that use Sidekiq's own API directly
(`include Sidekiq::Job`, `perform_async`), which doesn't go through
ActiveJob at all.

```ruby
require "idempotency_check/sidekiq"

IdempotencyCheck.idempotent? { MyWorker.perform_async(user_id) }
```

## What it doesn't cover (yet)

- Automatic retries (`retry_on`/`discard_on`) — the checker runs the block
  cleanly 3 times, it doesn't simulate a mid-run failure and retry.
- Cache/Redis side effects (e.g. `Rails.cache.increment`).
- External storage (S3, ActiveStorage).
- Real concurrency — every run is sequential, not parallel.

## Development

```bash
cd gem
bundle install
bundle exec rake test
```
