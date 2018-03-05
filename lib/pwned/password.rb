require "digest"

module Pwned
  class Password
    attr_reader :password

    def initialize(password)
      @password = password
    end

    def hashed_password
      Digest::SHA1.hexdigest(password).upcase
    end
  end
end