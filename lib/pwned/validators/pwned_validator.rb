# frozen_string_literal: true

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