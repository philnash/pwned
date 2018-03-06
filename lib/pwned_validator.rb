class PwnedValidator < ActiveModel::EachValidator
  # We do not want to break customer sign-up process when the service is down.
  DEFAULT_ON_ERROR = :valid

  def validate_each(record, attribute, value)
    begin
      pwned_check = Pwned::Password.new(value)
      if pwned_check.pwned?
        record.errors.add(attribute, :pwned, options.merge(count: pwned_check.pwned_count))
      end
    rescue Pwned::Error
      case on_error
      when :invalid
        record.errors.add(attribute, :pwned_error, options.merge(message: options[:error_message]))
      when :valid
        # Do nothing, consider the record valid
      else
        raise
      end
    end
  end

  def on_error
    options[:on_error] || DEFAULT_ON_ERROR
  end
end
