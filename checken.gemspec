require_relative './lib/checken/version'
Gem::Specification.new do |s|
  s.name          = "checken"
  s.description   = %q{An authorization framework for Ruby & Rails applications.}
  s.summary       = %q{This gem provides a friendly DSL for managing and enforcing permissions.}
  s.homepage      = "https://github.com/adamcooke/checken"
  s.version       = Checken::VERSION
  s.files         = Dir.glob("{lib}/**/*")
  s.require_paths = ["lib"]
  s.authors       = ["Adam Cooke"]
  s.email         = ["me@adamcooke.io"]
  s.licenses      = ['MIT']
end
