# frozen_string_literal: true

require "digest"
require "pwned/version"
require "pwned/error"
require "pwned/password"
require "pwned/hashed_password"

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
  @default_request_options = {}

  ##
  # The default request options passed to +Net::HTTP.start+ when calling the API.
  #
  # @return [Hash]
  # @see Pwned::Password#initialize
  def self.default_request_options
    @default_request_options
  end

  ##
  # Sets the default request options passed to +Net::HTTP.start+ when calling
  # the API.
  #
  # The default options may be overridden in +Pwned::Password#new+.
  #
  # @param [Hash] request_options
  # @see Pwned::Password#initialize
  def self.default_request_options=(request_options)
    @default_request_options = request_options
  end

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
  # @option request_options [Symbol] :headers ({ "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" })
  #   HTTP headers to include in the request
  # @option request_options [Symbol] :ignore_env_proxy (false) The library
  #   will try to infer an HTTP proxy from the `http_proxy` environment
  #   variable. If you do not want this behaviour, set this option to true.
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
  # @option request_options [Symbol] :headers ({ "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" })
  #   HTTP headers to include in the request
  # @option request_options [Symbol] :ignore_env_proxy (false) The library
  #   will try to infer an HTTP proxy from the `http_proxy` environment
  #   variable. If you do not want this behaviour, set this option to true.
  # @return [Integer] The number of times the password has appeared in the data
  #   breaches.
  # @since 1.1.0
  def self.pwned_count(password, request_options={})
    Pwned::Password.new(password, request_options).pwned_count
  end

  ##
  # Returns the full SHA1 hash of the given password in uppercase. This can be safely passed around your code
  # before making the pwned request (e.g. dropped into a queue table).
  #
  # @example
  #     Pwned.hash_password("password") #=> 5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8
  #
  # @param password [String] The password you want to check against the API
  # @return [String] An uppercase SHA1 hash of the password
  # @since 2.1.0
  def self.hash_password(password)
    Digest::SHA1.hexdigest(password).upcase
  end
end
