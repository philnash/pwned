# frozen_string_literal: true

module Pwned
  ##
  # A base error for HTTP request errors that may be thrown when making requests
  # to the Pwned Passwords API.
  #
  # @see Pwned::Password#pwned?
  # @see Pwned::Password#pwned_count
  class Error < StandardError
  end
end
