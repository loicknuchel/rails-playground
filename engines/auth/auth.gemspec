require_relative "lib/auth/version"

Gem::Specification.new do |spec|
  spec.name        = "auth"
  spec.version     = Auth::VERSION
  spec.authors     = ["Loïc Knuchel"]
  spec.summary     = "An engine managing authentication"
  spec.add_dependency "rails", "~> 6.1.1"
end
