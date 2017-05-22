module Osm

  class Register

    # Get register structure
    # @param api [Osm::Api] The api to use to make the request
    # @param [section Osm::Section, Integer, #to_i] The section (or its ID) to get the structure for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the structure for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Register::Field>] representing the fields of the register
    def self.get_structure(api:, section:, term: nil, no_read_cache: false)
      Osm::Model.require_ability_to(api: api, to: :read, on: :register, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section).id : term.to_i
      cache_key = ['register_structure', section_id, term_id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("users.php?action=registerStructure&sectionid=#{section_id}&termid=#{term_id}")

        structure = []
        if data.is_a?(Array)
          data = (data.size == 2) ? data[1] : []
          if data.is_a?(Hash) && data['rows'].is_a?(Array)
            data['rows'].each do |row|
              structure.push Field.new(
                id: row['field'],
                name: row['name'],
                tooltip: row['tooltip'],
              )
            end
          end
        end
        structure
      end # cache fetch
    end

    # Get register attendance
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the register for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the register for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Register::Attendance>] representing the attendance of each member
    def self.get_attendance(api:, section:, term: nil, no_read_cache: false)
      Osm::Model.require_ability_to(api: api, to: :read, on: :register, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section).id : term.to_i
      cache_key = ['register_attendance', section_id, term_id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("users.php?action=register&sectionid=#{section_id}&termid=#{term_id}")
        dates_s = get_structure(api: api, section: section, term: term, no_read_cache: no_read_cache)
        dates_s = dates_s.map{ |f| f.id }
        dates_d = dates_s.map{ |d| Osm::parse_date(d) }

        to_return = []
        if data.is_a?(Hash) && data['items'].is_a?(Array)
          data = data['items']
          data.each do |item|
            if item.is_a?(Hash)
              unless item['scoutid'].to_i < 0  # It's a total row
                attendance = {}
                dates_d.each_with_index do |date, index|
                  item_attendance = item[dates_s[index]]
                  attendance[date] = :unadvised_absent
                  attendance[date] = :yes if item_attendance.eql?('Yes')
                  attendance[date] = :advised_absent if item_attendance.eql?('No')
                end
                to_return.push Osm::Register::Attendance.new(
                  member_id: Osm::to_i_or_nil(item['scoutid']),
                  grouping_id: Osm::to_i_or_nil(item ['patrolid']),
                  section_id: section_id,
                  first_name: item['firstname'],
                  last_name: item['lastname'],
                  total: item['total'].to_i,
                  attendance: attendance,
                )
              end
            end
          end
        end
        to_return
      end # cache fetch
    end

    # Update attendance for an evening in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section] the section to update the register for
    # @param term [Osm::Term, #to_i, nil] The term (or its ID) to get the register for, passing nil causes the current term to be used
    # @param date [Osm::Evening, DateTime, Date] the date to update the register on
    # @param attendance [Symbol] what to mark the attendance as, one of :yes, :unadvised_absent or :advised_absent
    # @param members [Integer, Array<Integer>, Osm::Member, Array<Osm::Member>] the members (or their ids) to update
    # @param completed_badge_requirements [Array<Hash>] the badge requirements to mark as completed, selected from the Hash returned by the get_badge_requirements_for_evening method
    # @return true, false whether the update succedded
    # @raise [Osm::ArgumentIsInvalid] If data[:attendance] is not "Yes", "No" or "Absent"
    # @raise [Osm::ArgumentIsInvalid] If data[:section] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:evening] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:members] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:api] is missing
    def self.update_attendance(api:, section:, term:, date:, attendance:,  members:, completed_badge_requirements: [])
      fail Osm::ArgumentIsInvalid, 'attendance is invalid' unless [:yes, :unadvised_absent, :advised_absent].include?(attendance)
      Osm::Model.require_ability_to(api: api, to: :write, on: :register, section: section)

      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section).id : term.to_i
      members = [*members].map{ |member| (member.is_a?(Integer) ? member : member.id).to_s } # Make sure it's an Array of Strings

      response = api.post_query("users.php?action=registerUpdate&sectionid=#{section.id}&termid=#{term_id}", post_data: {
        'scouts' => members.inspect,
        'selectedDate' => date.strftime(Osm::OSM_DATE_FORMAT),
        'present' => {yes: 'Yes', unadvised_absent: nil, advised_absent: 'No'}[attendance],
        'section' => section.type,
        'sectionid' => section.id,
        'completedBadges' => completed_badge_requirements.to_json
      })

      # The cached attendance will be out of date - remove them
      Osm::Model.cache_delete(api: api, key: ['register_attendance', section.id, term_id])

      return response.is_a?(Array)
    end


    class Field < Osm::Model
      # @!attribute [rw] id
      #   @return [String] OSM identifier for the field
      # @!attribute [rw] name
      #   @return [String] Human readable name for the field
      # @!attribute [rw] tooltip
      #   @return [String] Tooltip for the field

      attribute :id, type: String
      attribute :name, type: String
      attribute :tooltip, type: String, default: ''

      validates_presence_of :id
      validates_presence_of :name
      validates_presence_of :tooltip, allow_blank: true


      # @!method initialize
      #   Initialize a new RegisterField
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

    end # Class Register::Field


    class Attendance < Osm::Model
      # @!attribute [rw] member_id
      #   @return [Integer] The OSM ID for the member
      # @!attribute [rw] grouping_id
      #   @return [Integer] The OSM ID for the member's grouping
      # @!attribute [rw] section_id
      #   @return [Integer] The OSM ID for the member's section
      # @!attribute [rw] first_name
      #   @return [String] The member's first name
      # @!attribute [rw] last_name
      #   @return [String] The member's last name
      # @!attribute [rw] total
      #   @return [FixNum] Total
      # @!attribute [rw] attendance
      #   @return [Hash] The data for each field - keys are the date, values one of :yes, :unadvised_absent or :advised_absent

      attribute :member_id, type: Integer
      attribute :grouping_id, type: Integer
      attribute :section_id, type: Integer
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :total, type: Integer
      attribute :attendance, default: {}

      validates_numericality_of :member_id, only_integer:true, greater_than:0
      validates_numericality_of :grouping_id, only_integer:true, greater_than_or_equal_to:-2
      validates_numericality_of :section_id, only_integer:true, greater_than:0
      validates_numericality_of :total, only_integer:true, greater_than_or_equal_to:0
      validates_presence_of :first_name
      validates_presence_of :last_name

      validates :attendance, hash: {key_type: Date, value_in: [:yes, :unadvised_absent, :advised_absent]}


      # @!method initialize
      #   Initialize a new registerData
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Find out if the member was present on a date
      # @param [Date] date The date to check attendance for
      # @return true, false whether the member was presnt on the given date
      def present_on?(date)
        attendance[date] == :yes
      end

      # Find out if the member was absent on a date
      # @param [Date] date The date to check attendance for
      # @return true, false whether the member was absent on the given date
      def absent_on?(date)
        attendance[date] != :yes
      end

      private
      def sort_by
        [:section_id, :grouping_id, :last_name, :first_name]
      end
    end # Class Register::Attendance

  end # Class Register
  
end # Module
