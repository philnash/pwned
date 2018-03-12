# frozen_string_literal: true

class PwnedValidator < ActiveModel::EachValidator
  # We do not want to break customer sign-up process when the service is down.
  DEFAULT_ON_ERROR = :valid
  DEFAULT_THRESHOLD = 0

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
