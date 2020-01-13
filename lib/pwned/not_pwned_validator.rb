# frozen_string_literal: true

##
# An +ActiveModel+ validator to check passwords against the Pwned Passwords API.
#
# @example Validate a password on a +User+ model with the default options.
#     class User < ApplicationRecord
#       validates :password, not_pwned: true
#     end
#
# @example Validate a password on a +User+ model with a custom error message.
#     class User < ApplicationRecord
#       validates :password, not_pwned: { message: "has been pwned %{count} times" }
#     end
#
# @example Validate a password on a +User+ model that allows the password to have been breached once.
#     class User < ApplicationRecord
#       validates :password, not_pwned: { threshold: 1 }
#     end
#
# @example Validate a password on a +User+ model, handling API errors in various ways
#     class User < ApplicationRecord
#       # The record is marked as invalid on network errors
#       # (error message "could not be verified against the past data breaches".)
#       validates :password, not_pwned: { on_error: :invalid }
#
#       # The record is marked as invalid on network errors with custom error.
#       validates :password, not_pwned: { on_error: :invalid, error_message: "might be pwned" }
#
#       # An error is raised on network errors.
#       # This means that `record.valid?` will raise `Pwned::Error`.
#       # Not recommended to use in production.
#       validates :password, not_pwned: { on_error: :raise_error }
#
#       # Call custom proc on error. For example, capture errors in Sentry,
#       # but do not mark the record as invalid.
#       validates :password, not_pwned: {
#         on_error: ->(record, error) { Raven.capture_exception(error) }
#       }
#     end
#
# @since 1.2.0
class NotPwnedValidator < ActiveModel::EachValidator
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
  #
  # The validation will short circuit and return with no errors added if the
  # password is blank. The +Pwned::Password+ initializer expects the password to
  # be a string and will throw a +TypeError+ if it is +nil+. Also, technically
  # the empty string is not a password that is reported to be found in data
  # breaches, so returns +false+, short circuiting that using +value.blank?+
  # saves us a trip to the API.
  #
  # @param record [ActiveModel::Validations] The object being validated
  # @param attribute [Symbol] The attribute on the record that is currently
  #   being validated.
  # @param value [String] The value of the attribute on the record that is the
  #   subject of the validation
  def validate_each(record, attribute, value)
    return if value.blank?
    begin
      pwned_check = Pwned::Password.new(value, request_options)
      if pwned_check.pwned_count > threshold
        record.errors.add(attribute, :not_pwned, **options.merge(count: pwned_check.pwned_count))
      end
    rescue Pwned::Error => error
      case on_error
      when :invalid
        record.errors.add(attribute, :pwned_error, **options.merge(message: options[:error_message]))
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
    raise TypeError, "#{self.class.to_s} option 'threshold' must be of type Integer" unless threshold.is_a? Integer
    threshold
  end
end

##
# The version 1.1.0 validator that uses `pwned` in the validate method.
# This has been updated to the above `not_pwned` validator to be clearer what
# is being validated.
#
# This class is being maintained for backwards compatitibility but will be
# removed
#
# @example Validate a password on a +User+ model with the default options.
#     class User < ApplicationRecord
#       validates :password, pwned: true
#     end
#
# @deprecated use the +NotPwnedValidator+ instead.
#
# @since 1.1.0
class PwnedValidator < NotPwnedValidator
end
