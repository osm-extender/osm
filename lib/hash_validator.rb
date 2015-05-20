class HashValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'must be a Hash') unless value.is_a?(Hash)

    value.each do |k, v|
      if options[:key_type]
        unless k.is_a?(options[:key_type])
          record.errors.add(attribute, "keys must be a #{options[:key_type].name} (#{k.inspect} is not).")
        end
      end

      if options[:key_in]
        unless options[:key_in].include?(k)
          record.errors.add(attribute, "keys must be in #{options[:key_in].inspect} (#{k.inspect} is not).")
        end
      end


      if options[:value_type]
        unless v.is_a?(options[:value_type])
          record.errors.add(attribute, "values must be a #{options[:value_type].name} (#{v.inspect} for key #{k.inspect} is not).")
        end
      end

      if options[:value_in]
        unless options[:value_in].include?(v)
          record.errors.add(attribute, "values must be in #{options[:value_in].inspect} (#{v.inspect} for key #{k.inspect} is not).")
        end
      end
    end
  end
end
