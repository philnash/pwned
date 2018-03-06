# frozen_string_literal: true

require "digest"
require "open-uri"

module Pwned
  class Password
    API_URL = "https://api.pwnedpasswords.com/range/"
    HASH_PREFIX_LENGTH = 5
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
      regex = /#{Regexp.escape hashed_password[HASH_PREFIX_LENGTH..-1]}:(\d+)/
      @pwned_count ||= hashes[regex, 1].to_i
    end

    private

    def hashes
      @hashes || get_hashes
    end

    def get_hashes
      begin
        open("#{API_URL}#{hashed_password[0...HASH_PREFIX_LENGTH]}", @request_options) do |io|
          @hashes = io.read
        end
        @hashes
      rescue Timeout::Error => e
        raise Pwned::TimeoutError, e.message
      rescue => e
        raise Pwned::Error, e.message
      end
    end
  end
end
