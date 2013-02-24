module Osm

  class Register

    # Get register structure
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the structure for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the structure for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Register::Field>] representing the fields of the register
    def self.get_structure(api, section, term=nil, options={})
      Osm::Model.require_ability_to(api, :read, :register, section, options)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['register_structure', section_id, term_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("users.php?action=registerStructure&sectionid=#{section_id}&termid=#{term_id}")

      structure = []
      if data.is_a?(Array)
        data.each do |item|
          if item.is_a?(Hash) && item['rows'].is_a?(Array)
            item['rows'].each do |row|
              structure.push Field.new(
                :id => row['field'],
                :name => row['name'],
                :tooltip => row['tooltip'],
              )
            end
          end
        end
      end

      Osm::Model.cache_write(api, cache_key, structure) unless structure.nil?
      return structure
    end

    # Get register attendance
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the register for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the register for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Register::Attendance>] representing the attendance of each member
    def self.get_attendance(api, section, term=nil, options={})
      Osm::Model.require_ability_to(api, :read, :register, section, options)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['register_attendance', section_id, term_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("users.php?action=register&sectionid=#{section_id}&termid=#{term_id}")

      to_return = []
      if data.is_a?(Hash) && data['items'].is_a?(Array)
        data = data['items']
        data.each do |item|
          if item.is_a?(Hash)
            unless item['scoutid'].to_i < 0  # It's a total row
              to_return.push Osm::Register::Attendance.new(
                :member_id => Osm::to_i_or_nil(item['scoutid']),
                :grouping_id => Osm::to_i_or_nil(item ['patrolid']),
                :section_id => section_id,
                :first_name => item['firstname'],
                :last_name => item['lastname'],
                :total => item['total'].to_i,
                :attendance => item.select { |key, value| key.to_s.match(Osm::OSM_DATE_REGEX) }.
                                    inject({}){ |new_hash,(date, attendance)| new_hash[Date.strptime(date, Osm::OSM_DATE_FORMAT)] = attendance; new_hash },
              )
            end
          end
        end
        Osm::Model.cache_write(api, cache_key, to_return)
      end
      return to_return
    end

    # Update attendance for an evening in OSM
    # @param [Hash] data
    # @option data [Osm::Api] :api The api to use to make the request
    # @option data [Osm::Section] :section the section to update the register for
    # @option data [Osm::Term, #to_i, nil] :term The term (or its ID) to get the register for, passing nil causes the current term to be used
    # @option data [Osm::Evening, DateTime, Date] :evening the evening to update the register on
    # @option data [String] :attendance what to mark the attendance as, one of "Yes", "No" or "Absent"
    # @option data [Fixnum, Array<Fixnum>, Osm::Member, Array<Osm::Member>] :members the members (or their ids) to update
    # @option data [Array<Hash>] :completed_badge_requirements (optional) the badge requirements to mark as completed, selected from the Hash returned by the get_badge_requirements_for_evening method
    # @return [Boolean] whether the update succedded
    # @raise [Osm::ArgumentIsInvalid] If data[:attendance] is not "Yes", "No" or "Absent"
    # @raise [Osm::ArgumentIsInvalid] If data[:section] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:evening] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:members] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:api] is missing
    def self.update_attendance(data={})
      raise Osm::ArgumentIsInvalid, ':attendance is invalid' unless ['Yes', 'No', 'Absent'].include?(data[:attendance])
      raise Osm::ArgumentIsInvalid, ':section is missing' if data[:section].nil?
      raise Osm::ArgumentIsInvalid, ':evening is missing' if data[:evening].nil?
      raise Osm::ArgumentIsInvalid, ':members is missing' if data[:members].nil?
      raise Osm::ArgumentIsInvalid, ':api is missing' if data[:api].nil?
      api = data[:api]
      Osm::Model.require_ability_to(api, :write, :register, data[:section])

      term_id = data[:term].nil? ? Osm::Term.get_current_term_for_section(api, section).id : data[:term].to_i

      data[:members] = [*data[:members]].map{ |member| (member.is_a?(Fixnum) ? member : member.id).to_s } # Make sure it's an Array of Strings

      response = api.perform_query("users.php?action=registerUpdate&sectionid=#{data[:section].id}&termid=#{term_id}", {
        'scouts' => data[:members].inspect,
        'selectedDate' => data[:evening].strftime(Osm::OSM_DATE_FORMAT),
        'present' => data[:attendance],
        'section' => data[:section].type,
        'sectionid' => data[:section].id,
        'completedBadges' => (data[:completed_badge_requirements] || []).to_json
      })

      # The cached attendance will be out of date - remove them
      Osm::Model.cache_delete(api, ['register_attendance', data[:section].id, term_id])

      return response.is_a?(Array)
    end


    class Field < Osm::Model
      # @!attribute [rw] id
      #   @return [String] OSM identifier for the field
      # @!attribute [rw] name
      #   @return [String] Human readable name for the field
      # @!attribute [rw] tooltip
      #   @return [String] Tooltip for the field

      attribute :id, :type => String
      attribute :name, :type => String
      attribute :tooltip, :type => String, :default => ''

      attr_accessible :id, :name, :tooltip

      validates_presence_of :id
      validates_presence_of :name
      validates_presence_of :tooltip, :allow_blank => true


      # @!method initialize
      #   Initialize a new RegisterField
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Compare Field based on id then version
      def <=>(another)
        return self.id <=> another.try(:id)
      end

    end # Class Register::Field


    class Attendance < Osm::Model
      # @!attribute [rw] member_id
      #   @return [Fixnum] The OSM ID for the member
      # @!attribute [rw] grouping_id
      #   @return [Fixnum] The OSM ID for the member's grouping
      # @!attribute [rw] section_id
      #   @return [Fixnum] The OSM ID for the member's section
      # @!attribute [rw] first_name
      #   @return [String] The member's first name
      # @!attribute [rw] last_name
      #   @return [String] The member's last name
      # @!attribute [rw] total
      #   @return [FixNum] Total
      # @!attribute [rw] attendance
      #   @return [Hash] The data for each field - keys are the date, values one of 'Yes' (present), 'No' (known absence) or nil (absent)

      attribute :member_id, :type => Integer
      attribute :grouping_id, :type => Integer
      attribute :section_id, :type => Integer
      attribute :first_name, :type => String
      attribute :last_name, :type => String
      attribute :total, :type => Integer
      attribute :attendance, :default => {}

      attr_accessible :member_id, :first_name, :last_name, :section_id, :grouping_id, :total, :attendance

      validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
      validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :total, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_presence_of :first_name
      validates_presence_of :last_name

      validates :attendance, :hash => {:key_type => Date, :value_in => ['Yes', 'No', nil]}


      # @!method initialize
      #   Initialize a new registerData
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Compare Attendance based on section_id, grouping_id, last_name then first_name
      def <=>(another)
        result = self.section_id <=> another.try(:section_id)
        result = self.grouping_id <=> another.try(:grouping_id) if result == 0
        result = self.last_name <=> another.try(:last_name) if result == 0
        result = self.first_name <=> another.try(:last_name) if result == 0
        return result
      end

    end # Class Register::Attendance

  end # Class Register
  
end # Module
