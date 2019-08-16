# frozen_string_literal: true

require "pwned/version"
require "pwned/error"
require "pwned/password"

begin
  # Load Rails and our custom validator
  require "active_model"
  require "pwned/not_pwned_validator"

  # Initialize I18n (validation error message)
  require "active_support/i18n"
  I18n.load_path.concat Dir[File.expand_path("locale/*.yml", __dir__)]
rescue LoadError
  # Not a Rails project, no need to do anything
end

##
# The main namespace for +Pwned+. Includes convenience methods for getting the
# results for a password.

module Pwned
  ##
  # Returns +true+ when the password has been pwned.
  #
  # @example
  #     Pwned.pwned?("password") #=> true
  #     Pwned.pwned?("pwned::password") #=> false
  #
  # @param password [String] The password you want to check against the API.
  # @param [Hash] request_options Options that can be passed to +Net::HTTP.start+ when
  #   calling the API
  # @option request_options [Symbol] :headers ({ "User-Agent" => '"Ruby Pwned::Password #{Pwned::VERSION}" })
  #   HTTP headers to include in the request
  # @return [Boolean] Whether the password appears in the data breaches or not.
  # @since 1.1.0
  def self.pwned?(password, request_options={})
    Pwned::Password.new(password, request_options).pwned?
  end

  ##
  # Returns number of times the password has been pwned.
  #
  # @example
  #     Pwned.pwned_count("password") #=> 3303003
  #     Pwned.pwned_count("pwned::password") #=> 0
  #
  # @param password [String] The password you want to check against the API.
  # @param [Hash] request_options Options that can be passed to +Net::HTTP.start+ when
  #   calling the API
  # @option request_options [Symbol] :headers ({ "User-Agent" => '"Ruby Pwned::Password #{Pwned::VERSION}" })
  #   HTTP headers to include in the request
  # @return [Integer] The number of times the password has appeared in the data
  #   breaches.
  # @since 1.1.0
  def self.pwned_count(password, request_options={})
    Pwned::Password.new(password, request_options).pwned_count
  end
end
