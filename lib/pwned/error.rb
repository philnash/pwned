module Pwned
  class Error < StandardError
    attr_reader :original_error

    def initialize(message, original_error)
      @original_error = original_error
      super(message)
    end
  end

  class TimeoutError < Error
  end
end