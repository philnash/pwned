# frozen_string_literal: true

require "pwned/version"
require "pwned/error"
require "pwned/password"

begin
  # Load Rails and our custom validator
  require "active_model"
  require "pwned/pwned_validator"

  # Initialize I18n (validation error message)
  require "active_support/i18n"
  I18n.load_path.concat Dir[File.expand_path('locale/*.yml', __dir__)]
rescue LoadError
  # Not a Rails project, no need to do anything
end

module Pwned
  # Returns true when the password has been pwned.
  def self.pwned?(password, request_options={})
    Pwned::Password.new(password, request_options).pwned?
  end

  # Returns number of times the password has been pwned.
  def self.pwned_count(password, request_options={})
    Pwned::Password.new(password, request_options).pwned_count
  end
end
