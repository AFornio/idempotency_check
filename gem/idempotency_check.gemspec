require_relative "lib/idempotency_check/version"

Gem::Specification.new do |spec|
  spec.name          = "idempotency_check"
  spec.version       = IdempotencyCheck::VERSION
  spec.summary       = "Detects whether a job (and eventually other units of work) is idempotent by running it twice and comparing effects"
  spec.authors       = ["Agustin Fornio"]
  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.0"
end
