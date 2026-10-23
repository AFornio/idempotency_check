# frozen_string_literal: true

require 'rake/testtask'
require 'rspec/core/rake_task'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test' << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = false
end

RSpec::Core::RakeTask.new(:spec)

task default: %i[test spec]
