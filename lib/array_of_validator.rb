class ArrayOfValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'must be an Array') unless value.is_a?(Array)
    value.each do |value_item|
      if value_item.is_a?(options[:item_type])
        # We don't want to check the item is valid if it's the wrong type
        unless options[:item_valid].nil?
          # Check validity of item matches item_valid option
          unless value_item.valid?.eql?(options[:item_valid])
            message = "contains #{value_item.valid? ? 'a valid' : 'an invalid'} item"
            record.errors.add(attribute, message)
          end
        end
      else
        record.errors.add(attribute, "items in the Array must be a #{options[:item_type].name}")
      end
    end
  end
end
