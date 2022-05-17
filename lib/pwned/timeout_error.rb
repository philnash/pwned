# frozen_string_literal: true

module Pwned
  ##
  # An error to represent when the Pwned Passwords API times out.
  #
  # @see Pwned::Password#pwned?
  # @see Pwned::Password#pwned_count
  class TimeoutError < Error
  end
end