# frozen_string_literal: true

##
# An +ActiveModel+ validator to check passwords against the Pwned Passwords API.
#
# @example Validate a password on a +User+ model with the default options.
#     class User < ApplicationRecord
#       validates :password, pwned: true
#     end
#
# @example Validate a password on a +User+ model with a custom error message.
#     class User < ApplicationRecord
#       validates :password, pwned: { message: "has been pwned %{count} times" }
#     end
#
# @example Validate a password on a +User+ model that allows the password to have been breached once.
#     class User < ApplicationRecord
#       validates :password, pwned: { threshold: 1 }
#     end
#
# @example Validate a password on a +User+ model, handling API errors in various ways
#     class User < ApplicationRecord
#       # The record is marked as invalid on network errors
#       # (error message "could not be verified against the past data breaches".)
#       validates :password, pwned: { on_error: :invalid }
#
#       # The record is marked as invalid on network errors with custom error.
#       validates :password, pwned: { on_error: :invalid, error_message: "might be pwned" }
#
#       # An error is raised on network errors.
#       # This means that `record.valid?` will raise `Pwned::Error`.
#       # Not recommended to use in production.
#       validates :password, pwned: { on_error: :raise_error }
#
#       # Call custom proc on error. For example, capture errors in Sentry,
#       # but do not mark the record as invalid.
#       validates :password, pwned: {
#         on_error: ->(record, error) { Raven.capture_exception(error) }
#       }
#     end
#
# @since 1.1.0
class PwnedValidator < ActiveModel::EachValidator
  ##
  # The default behaviour of this validator in the case of an API failure. The
  # default will mean that if the API fails the object will not be marked
  # invalid.
  DEFAULT_ON_ERROR = :valid

  ##
  # The default threshold for whether a breach is considered pwned. The default
  # is 0, so any password that appears in a breach will mark the record as
  # invalid.
  DEFAULT_THRESHOLD = 0

  ##
  # Validates the +value+ against the Pwned Passwords API. If the +pwned_count+
  # is higher than the optional +threshold+ then the record is marked as
  # invalid.
  #
  # In the case of an API error the validator will either mark the
  # record as valid or invalid. Alternatively it will run an associated proc or
  # re-raise the original error.
  def validate_each(record, attribute, value)
    begin
      pwned_check = Pwned::Password.new(value, request_options)
      if pwned_check.pwned_count > threshold
        record.errors.add(attribute, :pwned, options.merge(count: pwned_check.pwned_count))
      end
    rescue Pwned::Error => error
      case on_error
      when :invalid
        record.errors.add(attribute, :pwned_error, options.merge(message: options[:error_message]))
      when :valid
        # Do nothing, consider the record valid
      when Proc
        on_error.call(record, error)
      else
        raise
      end
    end
  end

  private

  def on_error
    options[:on_error] || DEFAULT_ON_ERROR
  end

  def request_options
    options[:request_options] || {}
  end

  def threshold
    threshold = options[:threshold] || DEFAULT_THRESHOLD
    raise TypeError, "PwnedValidator option 'threshold' must be of type Integer" unless threshold.is_a? Integer
    threshold
  end
end
