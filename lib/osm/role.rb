module Osm

  class Role
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model


    # @!attribute [rw] section
    #   @param [Osm::Section] section the section this role is related to
    #   @return [Osm::Section] the section this role related to
    # @!attribute [rw] group_name
    #   @return [String] the name of the group the section is in
    # @!attribute [rw] group_id
    #   @return [Fixnum] the group the section is in
    # @!attribute [rw] permissions
    #   @return [Hash] the permissions the user has in this role

    attribute :section, :type => Object
    attribute :group_name, :type => String
    attribute :group_id, :type => Integer
    attribute :permissions, :default => {}

    attr_accessible :section, :group_name, :group_id, :permissions


    validates_presence_of :section
    validates_numericality_of :group_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :group_name
    validates_presence_of :permissions, :unless => Proc.new { |a| a.permissions == {} }

    validates_each :permissions do |record, attr, value|
      record.errors.add(attr, 'must be a Hash') unless value.is_a?(Hash)
      value.each do |k, v|
        record.errors.add(attr, 'keys must be Symbols') unless k.is_a?(Symbol)
        record.errors.add(attr, 'values must be 10, 20 or 100') unless [10, 20, 100].include?(v)
      end
    end

    validates_each :section do |record, attr, value|
      unless value.nil?
        record.errors.add(attr, 'must also be valid') unless value.valid?
      end
    end


    # @!method initialize
    #   Initialize a new Role
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new Role from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      attributes = {}
      attributes[:group_name] = data['groupname']
      attributes[:group_id] = Osm::to_i_or_nil(data['groupid'])

      # Convert permission values to a number
      permissions = data['permissions'].is_a?(Hash) ? Osm::symbolize_hash(data['permissions']) : {}
      permissions.each_key do |key|
        permissions[key] = permissions[key].to_i
      end

      role = new(attributes.merge(:permissions => permissions))
      role.section = Osm::Section.from_api(data['sectionid'], data['sectionname'], ActiveSupport::JSON.decode(data['sectionConfig']), role)

      return role
    end

    # Determine if this role has read access for the provided permission
    # @param [Symbol] key the permission being queried
    # @return [Boolean] if this role can read the passed permission
    def can_read?(key)
      return [10, 20, 100].include?(permissions[key])
    end

    # Determine if this role has write access for the provided permission
    # @param [Symbol] key the permission being queried
    # @return [Boolean] if this role can write the passed permission
    def can_write?(key)
      return [20, 100].include?(permissions[key])
    end

    # Get section's long name in a consistent format
    # @return [String] e.g. "Scouts (1st Somewhere)"
    def long_name
      group_name.blank? ? section.name : "#{section.name} (#{group_name})"
    end

    # Get section's full name in a consistent format
    # @return [String] e.g. "1st Somewhere Beavers"
    def full_name
      group_name.blank? ? section.name : "#{group_name} #{section.name}"
    end

    def <=>(another_role)
      begin
        compare_group_name = group_name <=> another_role.group_name
        return compare_group_name unless compare_group_name == 0
  
        return 0 if section.type == another_role.section.type
        [:beavers, :cubs, :scouts, :explorers, :waiting, :adults].each do |type|
          return -1 if section.type == type
          return 1 if another_role.section.type == type
        end
      rescue NoMethodError
        return false
      end
    end

    def ==(another_role)
      begin
        return section == another_role.section
      rescue NoMethodError
        return false
      end
    end

    def inspect
      attribute_descriptions = attributes.merge('section' => section.inspect_without_role(self))
      return_inspect(attribute_descriptions)
    end

    def inspect_without_section(exclude_section)
      attribute_descriptions = (section == exclude_section) ? attributes.merge('section' => 'SET') : attributes
      return_inspect(attribute_descriptions)
    end


    private
    def return_inspect(attribute_descriptions)
      attribute_descriptions.sort.map { |key, value| "#{key}: #{key.eql?('section') ? value : value.inspect}" }.join(", ")
      separator = " " unless attribute_descriptions.empty?
      "#<#{self.class.name}#{separator}#{attribute_descriptions}>"
    end

  end # Class Role

end # Module
