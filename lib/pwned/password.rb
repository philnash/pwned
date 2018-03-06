# frozen_string_literal: true

require "digest"
require "open-uri"

module Pwned
  class Password
    API_URL = "https://api.pwnedpasswords.com/range/"
    HASH_PREFIX_LENGTH = 5
    SHA1_LENGTH = 40
    DEFAULT_REQUEST_OPTIONS = {
      "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}"
    }.freeze

    attr_reader :password

    def initialize(password, request_options={})
      raise TypeError, "password must be of type String" unless password.is_a? String
      @password = password
      @request_options = DEFAULT_REQUEST_OPTIONS.merge(request_options)
    end

    # Returns the full SHA1 hash of the given password.
    def hashed_password
      @hashed_password ||= Digest::SHA1.hexdigest(password).upcase
    end

    # Returns true when the password has been pwned.
    def pwned?
      pwned_count > 0
    end

    # Returns number of times the password has been pwned.
    def pwned_count
      @pwned_count || fetch_pwned_count
    end

    private

    def fetch_pwned_count
      suffix = hashed_password_suffix
      for_each_response_line do |line|
        next unless line.start_with?(suffix)
        # Count starts after the suffix, followed by a colon
        return @pwned_count = line[(SHA1_LENGTH-HASH_PREFIX_LENGTH+1)..-1].to_i
      end

      @pwned_count = 0
    rescue Timeout::Error => e
      raise Pwned::TimeoutError, e.message
    rescue => e
      raise Pwned::Error, e.message
    end

    def for_each_response_line(&block)
      open("#{API_URL}#{hashed_password_prefix}", @request_options) do |io|
        io.each_line(&block)
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
