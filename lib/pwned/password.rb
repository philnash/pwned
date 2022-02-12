# frozen_string_literal: true

require "pwned/password_base"
require "pwned/deep_merge"

module Pwned
  ##
  # This class represents a password. It does all the work of talking to the
  # Pwned Passwords API to find out if the password has been pwned.
  # @see https://haveibeenpwned.com/API/v2#PwnedPasswords
  class Password
    include PasswordBase
    using DeepMerge
    ##
    # @return [String] the password that is being checked.
    # @since 1.0.0
    attr_reader :password

    ##
    # Creates a new password object.
    #
    # @example A simple password with the default request options
    #     password = Pwned::Password.new("password")
    # @example Setting the user agent and the read timeout of the request
    #     password = Pwned::Password.new("password", headers: { "User-Agent" => "My user agent" }, read_timout: 10)
    #
    # @param password [String] The password you want to check against the API.
    # @param [Hash] request_options Options that can be passed to +Net::HTTP.start+ when
    #   calling the API. This overrides any keys specified in +Pwned.default_request_options+.
    # @option request_options [Symbol] :headers ({ "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" })
    #   HTTP headers to include in the request
    # @option request_options [Symbol] :ignore_env_proxy (false) The library
    #   will try to infer an HTTP proxy from the `http_proxy` environment
    #   variable. If you do not want this behaviour, set this option to true.
    # @raise [TypeError] if the password is not a string.
    # @since 1.1.0
    def initialize(password, request_options={})
      raise TypeError, "password must be of type String" unless password.is_a? String
      @password = password
      @hashed_password = Pwned.hash_password(password)
      @request_options = Pwned.default_request_options.deep_merge(request_options)
      @request_headers = Hash(@request_options.delete(:headers))
      @request_headers = DEFAULT_REQUEST_HEADERS.merge(@request_headers)
      @request_proxy = URI(@request_options.delete(:proxy)) if @request_options.key?(:proxy)
      @ignore_env_proxy = @request_options.delete(:ignore_env_proxy) || false
    end
  end
end
