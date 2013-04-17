module Osm

  class GiftAid

    # Get donations
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the structure for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the structure for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::GiftAid::Donation>] representing the donations made
    def self.get_donations(api, section, term=nil, options={})
      Osm::Model.require_ability_to(api, :read, :finance, section, options)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['gift_aid_donations', section_id, term_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("giftaid.php?action=getStructure&sectionid=#{section_id}&termid=#{term_id}")

      structure = []
      if data.is_a?(Array)
        data = (data.size == 2) ? data[1] : []
        if data.is_a?(Hash) && data['rows'].is_a?(Array)
          data['rows'].each do |row|
            structure.push Donation.new(
              :donation_date => Osm::parse_date(row['field']),
            )
          end
        end
      end

      Osm::Model.cache_write(api, cache_key, structure) unless structure.nil?
      return structure
    end

    # Get donation data
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the register for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the register for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::GiftAid::Data>] representing the donations of each member
    def self.get_data(api, section, term=nil, options={})
      Osm::Model.require_ability_to(api, :read, :finance, section, options)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['gift_aid_data', section_id, term_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("giftaid.php?action=getGrid&sectionid=#{section_id}&termid=#{term_id}")

      to_return = []
      if data.is_a?(Hash) && data['items'].is_a?(Array)
        data = data['items']
        data.each do |item|
          if item.is_a?(Hash)
            unless item['scoutid'].to_i < 0  # It's a total row
              donations = {}
              item.each do |key, value|
                if key.match(Osm::OSM_DATE_REGEX)
                  donations[Osm::parse_date(key)] = value
                end
              end
              to_return.push Osm::GiftAid::Data.new(
                :member_id => Osm::to_i_or_nil(item['scoutid']),
                :grouping_id => Osm::to_i_or_nil(item ['patrolid']),
                :section_id => section_id,
                :first_name => item['firstname'],
                :last_name => item['lastname'],
                :tax_payer => item['parentname'],
                :total => item['total'],
                :donations => donations,
              )
            end
          end
        end
        Osm::Model.cache_write(api, cache_key, to_return)
      end
      return to_return
    end

    # Update information for a donation
    # @param [Hash] data
    # @option data [Osm::Api] :api The api to use to make the request
    # @option data [Osm::Section] :section the section to update the register for
    # @option data [Osm::Term, #to_i, nil] :term The term (or its ID) to get the register for, passing nil causes the current term to be used
    # @option data [Osm::Evening, DateTime, Date] :evening the evening to update the register on
    # @option data [Fixnum, Array<Fixnum>, Osm::Member, Array<Osm::Member>, #to_i, Array<#to_i>] :members the members (or their ids) to update
    # @option data [Date, #strftime] :donation_date the date the donation was made
    # @option data [String, #to_s] :amount the donation amount
    # @option data [String, #to_s] :note the description for the donation
    # @return [Boolean] whether the update succedded
    # @raise [Osm::ArgumentIsInvalid] If data[:section] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:donation_date] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:amount] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:note] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:members] is missing
    # @raise [Osm::ArgumentIsInvalid] If data[:api] is missing
    def self.update_donation(data={})
      raise Osm::ArgumentIsInvalid, ':section is missing' if data[:section].nil?
      raise Osm::ArgumentIsInvalid, ':donation_date is missing' if data[:donation_date].nil?
      raise Osm::ArgumentIsInvalid, ':amount is missing' if data[:amount].nil?
      raise Osm::ArgumentIsInvalid, ':note is missing' if data[:note].nil?
      raise Osm::ArgumentIsInvalid, ':members is missing' if data[:members].nil?
      raise Osm::ArgumentIsInvalid, ':api is missing' if data[:api].nil?
      api = data[:api]
      Osm::Model.require_ability_to(api, :write, :finance, data[:section])

      term_id = data[:term].nil? ? Osm::Term.get_current_term_for_section(api, data[:section]).id : data[:term].to_i
      section_id = data[:section].to_i

      data[:members] = [*data[:members]].map{ |member| member.to_i.to_s } # Make sure it's an Array of Strings

      response = api.perform_query("giftaid.php?action=update&sectionid=#{section_id}&termid=#{term_id}", {
        'scouts' => data[:members].inspect,
        'sectionid' => section_id,
        'donatedate'=> data[:donation_date].strftime(Osm::OSM_DATE_FORMAT),
        'amount' => data[:amount],
        'notes' => data[:note],
      })

      # The cached donations and data will be out of date - remove them
      Osm::Model.cache_delete(api, ['gift_aid_donations', section_id, term_id])
      Osm::Model.cache_delete(api, ['gift_aid_data', section_id, term_id])

      return response.is_a?(Array)
    end

    class Donation < Osm::Model
      # @!attribute [rw] donation_date
      #   @return [Date] When the payment was made

      attribute :donation_date, :type => Date

      attr_accessible :note, :donation_date

      validates_presence_of :donation_date


      # @!method initialize
      #   Initialize a new RegisterField
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Compare Payment based on donation_date then note
      def <=>(another)
        return self.donation_date <=> another.try(:donation_date)
      end

    end # Class GiftAid::Donation


    class Data < Osm::Model
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
      # @!attribute [rw] tax_payer
      #   @return [String] The tax payer's name
      # @!attribute [rw] total
      #   @return [String] Total
      # @!attribute [rw] donations
      #   @return [DirtyHashy] The data for each payment - keys are the date, values are the value of the payment

      attribute :member_id, :type => Integer
      attribute :grouping_id, :type => Integer
      attribute :section_id, :type => Integer
      attribute :first_name, :type => String
      attribute :last_name, :type => String
      attribute :tax_payer, :type => String
      attribute :total, :type => String
      attribute :donations, :type => Object, :default => DirtyHashy.new

      attr_accessible :member_id, :first_name, :last_name, :section_id, :grouping_id, :total, :tax_payer, :donations

      validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
      validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
      validates_presence_of :first_name
      validates_presence_of :last_name

      validates :donations, :hash => {:key_type => Date, :value_type => String}


      # @!method initialize
      #   Initialize a new registerData
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      # Override initialize to set @orig_attributes
      old_initialize = instance_method(:initialize)
      define_method :initialize do |*args|
        ret_val = old_initialize.bind(self).call(*args)
        self.donations = DirtyHashy.new(self.donations)
        self.donations.clean_up!
        return ret_val
      end


      # Update data in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] whether the data was updated in OSM
      # @raise [Osm::ObjectIsInvalid] If the Data is invalid
      def update(api)
        raise Osm::ObjectIsInvalid, 'data is invalid' unless valid?
        require_ability_to(api, :write, :finance, section_id)
        term_id = Osm::Term.get_current_term_for_section(api, section_id).id

        updated = true
        if changed_attributes.include?('tax_payer')
          result = api.perform_query("giftaid.php?action=updateScout", {
            'scoutid' => member_id,
            'termid' => term_id,
            'column' => 'parentname',
            'value' => tax_payer,
            'sectionid' => section_id,
            'row' => 0,
          })
          if result.is_a?(Hash)
            (result['items'] || []).each do |i|
              if i['scoutid'] == member_id.to_s
                updated = false unless i['parentname'] == tax_payer
              end
            end
          end
        end
        reset_changed_attributes if updated

        donations.changes.each do |date, (was,now)|
          date = date.strftime(Osm::OSM_DATE_FORMAT)
          result = api.perform_query("giftaid.php?action=updateScout", {
            'scoutid' => member_id,
            'termid' => term_id,
            'column' => date,
            'value' => now,
            'sectionid' => section_id,
            'row' => 0,
          })
          if result.is_a?(Hash)
            (result['items'] || []).each do |i|
              if i['scoutid'] == member_id.to_s
                updated = false unless i[date] == now
              end
            end
          end
        end
        donations.clean_up! if updated

        Osm::Model.cache_delete(api, ['gift_aid_data', section_id, term_id]) if updated

        return updated
      end


      # Compare Data based on section_id, grouping_id, last_name then first_name
      def <=>(another)
        result = self.section_id <=> another.try(:section_id)
        result = self.grouping_id <=> another.try(:grouping_id) if result == 0
        result = self.last_name <=> another.try(:last_name) if result == 0
        result = self.first_name <=> another.try(:last_name) if result == 0
        return result
      end

    end # Class GiftAid::Data

  end # Class GiftAid

end
