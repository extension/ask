# From http://guides.rubyonrails.org/active_record_validations.html#custom-validators
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ User::EMAIL_VALIDATION_REGEX
      record.errors[attribute] << (options[:message] || "is not a valid email address")
    end
  end
end