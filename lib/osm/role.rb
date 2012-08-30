module Osm

  class Role

    attr_reader :section, :group_name, :group_id, :permissions
    # @!attribute [rw] section
    #   @param [Osm::Section] section the section this role is related to (can only be set once)
    #   @return [Osm::Section] the section this role related to
    # @!attribute [r] group_name
    #   @return [String] the name of the group the section is in
    # @!attribute [r] group_id
    #   @return [Fixnum] the group the section is in
    # @!attribute [r] permissions
    #   @return [Hash] the permissions the user has in this role

    # Initialize a new ApiAccess
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      raise ArgumentError, ':group_id must be nil or a Fixnum > 0' unless attributes[:group_id].nil? || (attributes[:group_id].is_a?(Fixnum) && attributes[:group_id] > 0)
      raise ArgumentError, ':group_name must be nil or a String' unless attributes[:group_name].nil? || attributes[:group_name].is_a?(String)
      raise ArgumentError, ':permissions must be nil or a Hash' unless attributes[:permissions].nil? || attributes[:permissions].is_a?(Hash)

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }

      @name ||= ''
      @permissions ||= {}
    end


    # Initialize a new ApiAccess from api data
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

    def section=(section)
      raise ArgumentError, 'section must be an Osm::Section' unless section.is_a?(Osm::Section)
      @section = section if @section.nil?
    end

    # Determine if this role has read access for the provided permission
    # @param [Symbol] key the permission being queried
    # @return [Boolean] if this role can read the passed permission
    def can_read?(key)
      return [10, 20, 100].include?(@permissions[key])
    end

    # Determine if this role has write access for the provided permission
    # @param [Symbol] key the permission being queried
    # @return [Boolean] if this role can write the passed permission
    def can_write?(key)
      return [20, 100].include?(@permissions[key])
    end

    # Get section's long name in a consistent format
    # @return [String] e.g. "Scouts (1st Somewhere)"
    def long_name
      @group_name.blank? ? @section.name : "#{@section.name} (#{@group_name})"
    end

    # Get section's full name in a consistent format
    # @return [String] e.g. "1st Somewhere Beavers"
    def full_name
      @group_name.blank? ? @section.name : "#{@group_name} #{@section.name}"
    end

    def <=>(another_role)
      compare_group_name = self.group_name <=> another_role.group_name
      return compare_group_name unless compare_group_name == 0

      return 0 if self.section.type == another_role.section.type
      [:beavers, :cubs, :scouts, :explorers, :waiting, :adults].each do |type|
        return -1 if self.section.type == type
        return 1 if another_role.section.type == type
      end
    end

    def ==(another_role)
      self.section == another_role.try(:section)
    end

  end

end
