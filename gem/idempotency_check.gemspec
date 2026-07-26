require_relative "lib/idempotency_check/version"

Gem::Specification.new do |spec|
  spec.name          = "idempotency_check"
  spec.version       = IdempotencyCheck::VERSION
  spec.summary       = "Detects whether a job (and eventually other units of work) is idempotent by running it twice and comparing effects"
  spec.authors       = ["Agustin Fornio"]
  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.0"

  # Dev-only: needed to run this gem's own test suite (fixtures exercise
  # real ActiveRecord/ActionMailer/ActiveJob/Sidekiq side effects). None of
  # these are installed for someone who just installs the gem.
  spec.add_development_dependency "activejob"
  spec.add_development_dependency "actionmailer"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sidekiq"
  spec.add_development_dependency "sqlite3"
end
