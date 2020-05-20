# frozen_string_literal: true

require "digest"
require 'net/http'

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
    # The default request headers that are used to make HTTP requests to the
    # API. A user agent is provided as requested in the documentation.
    # @see https://haveibeenpwned.com/API/v2#UserAgent
    DEFAULT_REQUEST_HEADERS = {
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
      @request_options = Hash(request_options).dup
      @request_headers = Hash(request_options.delete(:headers))
      @request_headers = DEFAULT_REQUEST_HEADERS.merge(@request_headers)
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

    attr_reader :request_options, :request_headers

    def fetch_pwned_count
      for_each_response_line do |line|
        next unless line.start_with?(hashed_password_suffix)
        # Count starts after the suffix, followed by a colon
        return line[(SHA1_LENGTH-HASH_PREFIX_LENGTH+1)..-1].to_i
      end

      # The hash was not found, we can assume the password is not pwned [yet]
      0
    end

    def for_each_response_line(&block)
      begin
        with_http_response "#{API_URL}#{hashed_password_prefix}" do |response|
          response.value # raise if request was unsuccessful
          stream_response_lines(response, &block)
        end
      rescue Timeout::Error => e
        raise Pwned::TimeoutError, e.message
      rescue => e
        raise Pwned::Error, e.message
      end
    end

    def hashed_password_prefix
      hashed_password[0...HASH_PREFIX_LENGTH]
    end

    def hashed_password_suffix
      hashed_password[HASH_PREFIX_LENGTH..-1]
    end

    # Make a HTTP GET request given the url and headers.
    # Yields a `Net::HTTPResponse`.
    def with_http_response(url, &block)
      uri = URI(url)

      request = Net::HTTP::Get.new(uri)
      request.initialize_http_header(request_headers)
      request_options[:use_ssl] = true

      Net::HTTP.start(uri.host, uri.port, request_options) do |http|
        http.request(request, &block)
      end
    end

    # Stream a Net::HTTPResponse by line, handling lines that cross chunks.
    def stream_response_lines(response, &block)
      last_line = ''

      response.read_body do |chunk|
        chunk_lines = (last_line + chunk).lines
        # This could end with half a line, so save it for next time. If
        # chunk_lines is empty, pop returns nil, so this also ensures last_line
        # is always a string.
        last_line = chunk_lines.pop || ''
        chunk_lines.each(&block)
      end

      yield last_line unless last_line.empty?
    end

  end
end
