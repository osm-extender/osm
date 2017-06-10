module Osm
  class Badge < Osm::Model
    class Data < Osm::Model
      # @!attribute [rw] member_id
      #   @return [Integer] ID of the member this data relates to
      # @!attribute [rw] first_name
      #   @return [Integer] the member's first name
      # @!attribute [rw] last_name
      #   @return [Integer] the member's last name
      # @!attribute [rw] due
      #   @return [Integer] whether this badge is due according to OSM, number indicates stage if appropriate
      # @!attribute [rw] awarded
      #   @return [Date] the last stage awarded
      # @!attribute [rw] awarded_date
      #   @return [Date] when the badge was awarded
      # @!attribute [rw] requirements
      #   @return [DirtyHashy] the data for each badge requirement
      # @!attribute [rw] section_id
      #   @return [Integer] the ID of the section the member belongs to
      # @!attribute [rw] badge
      #   @return [Osm::Badge] the badge that the data belongs to

      attribute :member_id, type: Integer
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :due, type: Integer, default: 0
      attribute :awarded, type: Integer, default: 0
      attribute :awarded_date, type: Date, default: nil
      attribute :requirements, type: Object, default: DirtyHashy.new
      attribute :section_id, type: Integer
      attribute :badge, type: Object

      validates_presence_of :badge
      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_numericality_of :due, only_integer: true, greater_than_or_equal_to: 0
      validates_numericality_of :awarded, only_integer: true, greater_than_or_equal_to: 0
      validates_numericality_of :member_id, only_integer: true, greater_than: 0
      validates_numericality_of :section_id, only_integer: true, greater_than: 0
      validates :requirements, hash: { key_type: Integer, value_type: String }


      # @!method initialize
      #   Initialize a new Badge::Data
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      # Override initialize to set @orig_attributes
      old_initialize = instance_method(:initialize)
      define_method :initialize do |*args|
        ret_val = old_initialize.bind(self).call(*args)
        self.requirements = DirtyHashy.new(requirements)
        requirements.clean_up!
        return ret_val
      end


      # Get the total number of gained requirements
      # @return [Integer] the total number of requirements considered gained
      def total_gained
        count = 0
        badge.requirements.each do |requirement|
          next unless requirement_met?(requirement.id)
          count += 1
        end
        count
      end

      # Get the letters of modules gained
      # @return [Array<Stirng>]
      def modules_gained
        g_i_m = gained_in_modules
        gained = []
        badge.modules.each do |mod|
          next if g_i_m[mod.id] < mod.min_required
          gained.push mod.letter
        end
        gained
      end

      # Get the number of requirements gained in each module
      # @return [Hash]
      def gained_in_modules
        count = {}
        badge.modules.each do |mod|
          count[mod.id] ||= 0
          count[mod.letter] ||= 0
        end
        badge.requirements.each do |requirement|
          next unless requirement_met?(requirement.id)
          count[requirement.mod.id] += 1
          count[requirement.mod.letter] += 1
        end
        count
      end


      # Check if this badge has been earnt
      # @return true, false whether the badge has been earnt (ignores other badge's and their requirements which might be needed)
      def earnt?
        if badge.has_levels?
          earnt > awarded
        else
          return false if (due.eql?(1) && awarded.eql?(1))
          return true if (due.eql?(1) && awarded.eql?(0))

          if badge.min_modules_required > 0
            return false unless modules_gained.size >= badge.min_modules_required
          end
          if badge.min_requirements_required > 0
            return false unless total_gained >= badge.min_requirements_required
          end
          if badge.requires_modules
            # [['a'], ['b', 'c']] = a and (b or c)
            requires = badge.requires_modules.clone
            modules = modules_gained
            requires.map!{ |a| a.map{ |b| modules.include?(b) } } # Replace letters with true/false
            requires.map!{ |a| a.include?(true) } # Replace each combination with true/false
            return false if requires.include?(false) # Only earnt if all combinations are met
          end
          badge.other_requirements_required.each do |c|
            # {id: ###, min: #}
            if requirements.has_key?(c[:id]) # Only check it if the data is in the requirements Hash
              return false unless requirement_met?(c[:id])
              return false if requirements[c[:id]].to_i < c[:min]
            end
          end
          badge.badges_required.each do |b|
            # {id: ###, version: #}
            #TODO
          end
          true
        end
      end


      # Get what stage which has most recently been earnt
      # (using #earnt? will tell you if it's still due (not yet awarded))
      # @return [Integer] the stage which has most recently been due
      def earnt
        unless badge.has_levels?
          return earnt? ? 1 : 0
        end

        levels_column = badge.level_requirement
        if badge.show_level_letters # It's a hikes, nights type badge
          modules = modules_gained
          letters = ('a'..'z').to_a
          (awarded..badge.levels.last).reverse_each do |level|
            return level if modules.include?(letters[level - 1])
          end
        else # It's an activity type badge
          badge.levels.reverse_each do |level|
            return level if requirements[levels_column].to_i >= level
          end
        end
        0
      end


      # Check if this badge has been started
      # @return true, false whether the badge has been started by the member (always false if the badge has been completed)
      def started?
        if badge.has_levels?
          return (started > due)
        end
        return false if due?
        requirements.each do |key, value|
          return true if requirement_met?(key)
        end
        false
      end


      # Get which stage has been started
      # @return [Integer] which stage of the badge has been started by the member (lowest)
      def started
        unless badge.has_levels?
          return started? ? 1 : 0
        end
        if badge.show_level_letters
          # 'Normal' staged
          letters = ('a'..'z').to_a
          top_level = badge.levels.last
          return 0 if due == top_level || awarded == top_level # No more levels to do
          ((due + 1)..top_level).reverse_each do |level|
            badge.requirements.each do |requirement|
              next unless requirement.mod.letter.eql?(letters[level - 1]) # Not interested in other levels
              return level if requirement_met?(requirement.id)
            end
          end
          return 0 # No levels started
        else
          # Nights, Hikes or Water
          done = requirements[badge.level_requirement].to_i
          levels = badge.levels                    # e.g. [0,1,2,3,4,5,10]
          return 0 if levels.include?(done)        # Has achieved a level (and not started next )
          return 0 if done >= levels.last          # No more levels to do
          (1..(levels.size - 1)).to_a.reverse_each do |i|  # indexes from last to 2nd
            this_level = levels[i]
            previous_level = levels[i - 1]
            return this_level if (done < this_level && done > previous_level) # this_level has been started (and not finished)
          end
          return 0 # No reason we should ever get here
        end
      end


      # Mark the badge as awarded in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @param date [Date] The date to mark the badge as awarded
      # @param level [Integer] The level of the badge to award (1 for non-staged badges), setting the level to 0 unawards the badge
      # @return true, false whether the data was updated in OSM
      def mark_awarded(api:, date: Date.today, level: due)
        fail ArgumentError, 'date is not a Date' unless date.is_a?(Date)
        fail ArgumentError, 'level can not be negative' if level < 0
        section = Osm::Section.get(api: api, section: section_id)
        require_ability_to(api, :write, :badge, section)

        date_formatted = date.strftime(Osm::OSM_DATE_FORMAT)
        entries = [{
          'badge_id' => badge.id.to_s,
          'badge_version' => badge.version.to_s,
          'scout_id' => member_id.to_s,
          'level' => level.to_s
        }]

        result = api.post_query('ext/badges/records/?action=awardBadge', post_data: {
          'date' => date_formatted,
          'sectionid' => section_id,
          'entries' => entries.to_json
        })
        updated = result.is_a?(Hash) &&
                  (result['scoutid'].to_i == member_id) &&
                  (result['awarded'].to_i == level) &&
                  (result['awardeddate'] == date_formatted)

        if updated
          awarded = level
          awarded_date = date
        end
        updated
      end

      # Mark the badge as not awarded in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the data was updated in OSM
      def mark_not_awarded(api)
        mark_awarded(api, Date.today, 0)
      end


      # Mark the badge as due in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @param level [Integer] The level of the badge to award (1 for non-staged badges), setting the level to 0 unawards the badge
      # @return true, false whether the data was updated in OSM
      def mark_due(api, level=earnt)
        fail ArgumentError, 'level can not be negative' if level < 0
        section = Osm::Section.get(api: api, section: section_id)
        require_ability_to(api, :write, :badge, section)

        result = api.post_query('ext/badges/records/?action=overrideCompletion', post_data: {
          'section_id' => section.id,
          'badge_id' => badge.id,
          'badge_version' => badge.version,
          'scoutid' => member_id,
          'level' => level
        })
        updated = result.is_a?(Hash) &&
                  (result['scoutid'].to_i == member_id) &&
                  (result['completed'].to_i == level)
        updated
      end

      # Mark the badge as not due in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the data was updated in OSM
      def mark_not_due(api)
        mark_due(api, 0)
      end

      # Update data in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the data was updated in OSM
      # @raise [Osm::ObjectIsInvalid] If the Data is invalid
      def update(api)
        fail Osm::ObjectIsInvalid, 'data is invalid' unless valid?
        section = Osm::Section.get(api: api, section: section_id)
        require_ability_to(api, :write, :badge, section)

        # Update requirements that changed
        requirements_updated = true
        editable_requirements = badge.requirements.select{ |r| r.editable }.map{ |r| r.id }
        requirements.changes.each do |requirement, (was,now)|
          next unless editable_requirements.include?(requirement)
          result = api.post_query('ext/badges/records/?action=updateSingleRecord', post_data: {
            'scoutid' => member_id,
            'section_id' => section_id,
            'badge_id' => badge.id,
            'badge_version' => badge.version,
            'field' => requirement,
            'value' => now
          })
          requirements_updated = false unless result.is_a?(Hash) &&
                                 (result['scoutid'].to_i == member_id) &&
                                 (result[requirement.to_s].to_s == now.to_s)
        end

        if requirements_updated
          requirements.clean_up!
        end

        # Update due if it changed
        due_updated = true
        if changed_attributes.include?('due')
          due_updated = mark_due(api, due)
        end

        # Update awarded if it changed 
        awarded_updated = true
        if changed_attributes.include?('awarded') || changed_attributes.include?('awarded_date')
          awarded_updated = mark_awarded(api, awarded_date, awarded)
        end

        # reset changed attributes if everything was updated ok
        if due_updated && awarded_updated
          reset_changed_attributes
        end

        requirements_updated && due_updated && awarded_updated
      end

      def inspect
        Osm.inspect_instance(self, replace_with: { 'badge' => :name })
      end

      # Work out if the requirmeent has been met
      # @param requirement_id [Integer, #to_i] The id of the requirement to evaluate (e.g. "12", "xSomething", "Yes" or "")
      # @return true, false whether the requirmeent has been met
      def requirement_met?(requirement_id)
        data = requirements[requirement_id.to_i].to_s
        return false if data == '0'
        !(data.blank? || data[0].downcase.eql?('x'))
      end

      protected

      def sort_by
        ['badge', 'section_id', 'member_id']
      end

    end
  end
end
