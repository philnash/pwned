# frozen_string_literal: true

require "pwned/version"
require "pwned/error"
require "pwned/password"

begin
  # Load Rails and our custom validator
  require "active_model"
  require_relative "pwned_validator"

  # Initialize I18n (validation error message)
  require "active_support/i18n"
  I18n.load_path.concat Dir[File.expand_path('locale/*.yml', __dir__)]
rescue LoadError
  # Not a Rails project, no need to do anything
end

module Pwned
end
