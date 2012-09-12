class ArrayOfValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'must be an Array') unless value.is_a?(Array)
    value.each do |value_item|
      unless value_item.is_a?(options[:item_type])
        record.errors.add(attribute, "items in the Array must be a #{options[:item_type].name}")
      else
        # We don't want to check the item is valid if it's the wrong type
        if !options[:item_valid].nil? && (value_item.valid? != options[:item_valid])
          record.errors.add(attribute, 'contains an invalid item')
        end
      end
    end
  end
end
