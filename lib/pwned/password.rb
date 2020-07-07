# frozen_string_literal: true

require 'pwned/password_base'

module Pwned
  ##
  # This class represents a password. It does all the work of talking to the
  # Pwned Passwords API to find out if the password has been pwned.
  # @see https://haveibeenpwned.com/API/v2#PwnedPasswords
  class Password < PasswordBase
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
    #   calling the API
    # @option request_options [Symbol] :headers ({ "User-Agent" => '"Ruby Pwned::Password #{Pwned::VERSION}" })
    #   HTTP headers to include in the request
    # @return [Boolean] Whether the password appears in the data breaches or not.
    # @raise [TypeError] if the password is not a string.
    # @since 1.1.0
    def initialize(password, request_options={})
      raise TypeError, "password must be of type String" unless password.is_a? String
      @password = password
      @hashed_password = Pwned.hash_password(password)
      @request_options = Hash(request_options).dup
      @request_headers = Hash(request_options.delete(:headers))
      @request_headers = DEFAULT_REQUEST_HEADERS.merge(@request_headers)
    end
  end
end
