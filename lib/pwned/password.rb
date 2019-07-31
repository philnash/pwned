# frozen_string_literal: true

require "digest"
require "open-uri"

module Pwned
  ##
  # This class represents a password. It does all the work of talking to the
  # Pwned Passwords API to find out if the password has been pwned.
  # @see https://haveibeenpwned.com/API/v2#PwnedPasswords
  class Password
    ##
    # The base URL for the Pwned Passwords API
    API_URL = "https://api.pwnedpasswords.com/range/"

    ##
    # The number of characters from the start of the hash of the password that
    # are used to search for the range of passwords.
    HASH_PREFIX_LENGTH = 5

    ##
    # The total length of a SHA1 hash
    SHA1_LENGTH = 40

    ##
    # The default request options that are used to make HTTP requests to the
    # API. A user agent is provided as requested in the documentation.
    # @see https://haveibeenpwned.com/API/v2#UserAgent
    DEFAULT_REQUEST_OPTIONS = {
      "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}"
    }.freeze

    ##
    # @return [String] the password that is being checked.
    # @since 1.0.0
    attr_reader :password

    ##
    # Creates a new password object.
    #
    # @example A simple password with the default request options
    #     password = Pwned::Password.new("password")
    # @example Setting the user agent and the read timeout of the reques
    #     password = Pwned::Password.new("password", "User-Agent" => "My user agent", :read_timout => 10)
    #
    # @param password [String] The password you want to check against the API.
    # @param [Hash] request_options Options that can be passed to +open+ when
    #   calling the API
    # @option request_options [String] 'User-Agent' ("Ruby Pwned::Password #{Pwned::VERSION}")
    #   The user agent used when making an API request.
    # @return [Boolean] Whether the password appears in the data breaches or not.
    # @raise [TypeError] if the password is not a string.
    # @since 1.1.0
    def initialize(password, request_options={})
      raise TypeError, "password must be of type String" unless password.instance_of? String
      @password = password
      @request_options = DEFAULT_REQUEST_OPTIONS.merge(request_options)
    end

    ##
    # Returns the full SHA1 hash of the given password in uppercase.
    # @return [String] The full SHA1 hash of the given password.
    # @since 1.0.0
    def hashed_password
      @hashed_password ||= Digest::SHA1.hexdigest(password).upcase
    end

    ##
    # @example
    #     password = Pwned::Password.new("password")
    #     password.pwned? #=> true
    #
    # @return [Boolean] +true+ when the password has been pwned.
    # @raise [Pwned::Error] if there are errors with the HTTP request.
    # @raise [Pwned::TimeoutError] if the HTTP request times out.
    # @since 1.0.0
    def pwned?
      pwned_count > 0
    end

    ##
    # @example
    #     password = Pwned::Password.new("password")
    #     password.pwned_count #=> 3303003
    #
    # @return [Integer] the number of times the password has been pwned.
    # @raise [Pwned::Error] if there are errors with the HTTP request.
    # @raise [Pwned::TimeoutError] if the HTTP request times out.
    # @since 1.0.0
    def pwned_count
      @pwned_count ||= fetch_pwned_count
    end

    private

    def fetch_pwned_count
      for_each_response_line do |line|
        next unless line.start_with?(hashed_password_suffix)
        # Count starts after the suffix, followed by a colon
        return Integer(line[(hashed_password_suffix.length+1)..-1])
      end

      # The hash was not found, we can assume the password is not pwned [yet]
      0
    end

    def for_each_response_line(&block)
      begin
        open("#{API_URL}#{hashed_password_prefix}", @request_options) do |io|
          io.each_line(&block)
        end
      rescue Timeout::Error => e
        raise TimeoutError, e
      rescue => e
        raise Error, e
      end
    end

    def hashed_password_prefix
      hashed_password[0...HASH_PREFIX_LENGTH]
    end

    def hashed_password_suffix
      hashed_password[HASH_PREFIX_LENGTH..-1]
    end
  end
end
