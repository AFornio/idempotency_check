# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Needed to run this gem's own test suite (fixtures exercise real
# ActiveRecord/ActionMailer/ActiveJob/Sidekiq side effects).
gem 'actionmailer', ENV.fetch('RAILS_VERSION', '>= 7.1')
gem 'activejob', ENV.fetch('RAILS_VERSION', '>= 7.1')
gem 'activerecord', ENV.fetch('RAILS_VERSION', '>= 7.1')
gem 'rake'
gem 'rspec'
gem 'rubocop', require: false
gem 'sidekiq'
gem 'sqlite3'
