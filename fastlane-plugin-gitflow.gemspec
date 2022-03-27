lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/gitflow/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-gitflow'
  spec.version       = Fastlane::Gitflow::VERSION
  spec.authors       = ['SaferMobility, LLC', 'Moshe Katz']
  spec.email         = 'support@safermobility.com'

  spec.summary       = 'Git-Flow actions for Fastlane'
  spec.description   = 'This plugin automates Git-Flow actions similar to git-flow-avh'
  spec.homepage      = "https://github.com/SaferMobility/fastlane-plugin-gitflow"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_development_dependency('bundler')
  spec.add_development_dependency('fastlane', '>= 2.205.1')
  spec.add_development_dependency('pry')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rubocop', '1.12.1')
  spec.add_development_dependency('rubocop-performance')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov')
end
