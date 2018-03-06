require "bundler/setup"
require "webmock/rspec"
require "pwned"

# Easily stub pwned password hash range API requests
require_relative "support/stub_pwned_range"

# No network requests in specs
WebMock.disable_net_connect!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
