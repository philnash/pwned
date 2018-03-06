require "digest"
require "open-uri"

module Pwned
  class Password
    API_URL = "https://api.pwnedpasswords.com/range/"
    HASH_PREFIX_LENGTH = 5
    DEFAULT_REQUEST_OPTIONS = {
      "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}"
    }

    attr_reader :password

    def initialize(password, request_options={})
      raise TypeError, "password must be of type String" unless password.is_a? String
      @password = password
      @request_options = DEFAULT_REQUEST_OPTIONS.merge(request_options)
    end

    def hashed_password
      Digest::SHA1.hexdigest(password).upcase
    end

    def pwned?
      !!match_data
    end

    def pwned_count
      match_data ? match_data[1].to_i : 0
    end

    private

    def hashes
      @hashes || get_hashes
    end

    def get_hashes
      open("#{API_URL}#{hashed_password[0...HASH_PREFIX_LENGTH]}", @request_options) do |io|
        @hashes = io.read
      end
      @hashes
    rescue Timeout::Error => e
      raise Pwned::TimeoutError, e.message
    rescue => e
      raise Pwned::Error, e.message
    end

    def match_data
      return @match_data if defined?(@match_data)
      @match_data = hashes.match(/#{hashed_password[HASH_PREFIX_LENGTH..-1]}:(\d+)/)
    end
  end
end
