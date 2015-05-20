class ValidityValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, "must be valid") unless value.try('valid?')
    error_messages = (value.try(:errors).try(:messages) || {})
    error_messages.each do |attr, messages|
      messages.each do |message|
        record.errors.add(attribute, "#{attr} attribute is invalid: #{message}")
      end # each message
    end # each attribute
  end
end
