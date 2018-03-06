class PwnedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    pwned_check = Pwned::Password.new(value)
    if pwned_check.pwned?
      record.errors.add(attribute, :pwned, options.merge(count: pwned_check.pwned_count))
    end
  end
end
