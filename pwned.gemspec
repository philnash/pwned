lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pwned/version"

Gem::Specification.new do |spec|
  spec.name          = "pwned"
  spec.version       = Pwned::VERSION
  spec.authors       = ["Phil Nash"]
  spec.email         = ["philnash@gmail.com"]

  spec.summary       = %q{Tools to use the Pwned Passwords API.}
  spec.description   = %q{Tools to use the Pwned Passwords API.}
  spec.homepage      = "https://github.com/philnash/pwned"
  spec.license       = "MIT"

  spec.metadata      = {
    "bug_tracker_uri"   => "https://github.com/philnash/pwned/issues",
    "change_log_uri"    => "https://github.com/philnash/pwned/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/pwned",
    "homepage_uri"      => "https://github.com/philnash/pwned",
    "source_code_uri"   => "https://github.com/philnash/pwned"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]
  spec.executables = ["pwned"]

  spec.add_development_dependency "bundler", ">= 1.16", "< 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.3"
  spec.add_development_dependency "yard", "~> 0.9.12"
end
