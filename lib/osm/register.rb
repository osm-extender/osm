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
                tooltip: row['tooltip']
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
        dates_s = dates_s.map(&:id)
        dates_d = dates_s.map { |d| Osm.parse_date(d) }

        to_return = []
        if data.is_a?(Hash) && data['items'].is_a?(Array)
          data = data['items']
          data.each do |item|
            next unless item.is_a?(Hash)
            unless item['scoutid'].to_i < 0  # It's a total row
              attendance = {}
              dates_d.each_with_index do |date, index|
                item_attendance = item[dates_s[index]]
                attendance[date] = :unadvised_absent
                attendance[date] = :yes if item_attendance.eql?('Yes')
                attendance[date] = :advised_absent if item_attendance.eql?('No')
              end
              to_return.push Osm::Register::Attendance.new(
                member_id: Osm.to_i_or_nil(item['scoutid']),
                grouping_id: Osm.to_i_or_nil(item ['patrolid']),
                section_id: section_id,
                first_name: item['firstname'],
                last_name: item['lastname'],
                total: item['total'].to_i,
                attendance: attendance
              )
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
      members = [*members].map { |member| (member.is_a?(Integer) ? member : member.id).to_s } # Make sure it's an Array of Strings

      response = api.post_query("users.php?action=registerUpdate&sectionid=#{section.id}&termid=#{term_id}", post_data: {
        'scouts' => members.inspect,
        'selectedDate' => date.strftime(Osm::OSM_DATE_FORMAT),
        'present' => { yes: 'Yes', unadvised_absent: nil, advised_absent: 'No' }[attendance],
        'section' => section.type,
        'sectionid' => section.id,
        'completedBadges' => completed_badge_requirements.to_json
      })

      # The cached attendance will be out of date - remove them
      Osm::Model.cache_delete(api: api, key: ['register_attendance', section.id, term_id])

      response.is_a?(Array)
    end

  end
end
