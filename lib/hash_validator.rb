class HashValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'must be a Hash') unless value.is_a?(Hash)

    value.each do |k, v|
      if options[:key_type]
        record.errors.add(attribute, "keys must be a #{options[:key_type].name}") unless k.is_a?(options[:key_type])
      end

      if options[:key_in]
        record.errors.add(attribute, "keys must be in #{options[:key_in].inspect}") unless options[:key_in].include?(k)
      end


      if options[:value_type]
        record.errors.add(attribute, "values must be a #{options[:value_type].name}") unless v.is_a?(options[:value_type])
      end

      if options[:value_in]
        record.errors.add(attribute, "values must be in #{options[:value_in].inspect}") unless options[:value_in].include?(v)
      end
    end
  end
end
