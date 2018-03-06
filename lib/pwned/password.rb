require "digest"
require "open-uri"

module Pwned
  class Password
    API_URL = "https://api.pwnedpasswords.com/range/"
    HASH_PREFIX_LENGTH = 5

    attr_reader :password

    def initialize(password)
      @password = password
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
      begin
        open("#{API_URL}#{hashed_password[0..(HASH_PREFIX_LENGTH-1)]}") do |io|
        # open("./spec/fixtures/#{hashed_password[0..(HASH_PREFIX_LENGTH-1)]}.txt") do |io|
          @hashes = io.read
        end
        @hashes
      rescue Timeout::Error => e
        raise Pwned::TimeoutError.new(e.message, e)
      rescue => e
        raise Pwned::Error.new(e.message, e)
      end
    end

    def match_data
      @match_data ||= hashes.match(/#{hashed_password[HASH_PREFIX_LENGTH..-1]}:(\d+)/)
    end

  end
end