# frozen_string_literal: true

require_relative 'lib/idempotency_check/version'

Gem::Specification.new do |spec|
  spec.name          = 'idempotency_check'
  spec.version       = IdempotencyCheck::VERSION
  spec.summary       = 'Detects non-idempotent jobs (or any Ruby block) by running them 3 times and comparing effects'
  spec.description   = <<~DESC
    idempotency_check runs a block of code multiple times and compares the
    side effects it produces (database rows, ActionMailer deliveries,
    ActiveJob enqueues, and optionally Sidekiq) to detect
    jobs that aren't safe to retry or re-run. It works on any block of Ruby
    code, not just jobs. Meant for test suites.
  DESC
  spec.authors       = ['Agustin Fornio']
  spec.email         = ['agustinfornio@gmail.com']
  spec.license       = 'MIT'
  spec.homepage      = 'https://github.com/AFornio/idempotency_check'
  spec.metadata      = {
    'source_code_uri' => 'https://github.com/AFornio/idempotency_check',
    'bug_tracker_uri' => 'https://github.com/AFornio/idempotency_check/issues',
    'rubygems_mfa_required' => 'true'
  }
  spec.files         = Dir['lib/**/*.rb'] + ['README.md', 'LICENSE.txt']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'activerecord', '>= 7.1', '< 9'
end
