module Osm

  class GiftAid

    # Get donations
    # @param api [Osm::Api] api The to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the structure for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the structure for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::GiftAid::Donation>] representing the donations made
    def self.get_donations(api:, section:, term: nil, no_read_cache: false)
      Osm::Model.require_ability_to(api: api, to: :read, on: :finance, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['gift_aid_donations', section_id, term_id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("giftaid.php?action=getStructure&sectionid=#{section_id}&termid=#{term_id}")

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
        structure
      end # cache fetch
    end

    # Get donation data
    # @param api [Osm::Api] api The to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the data for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the data for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::GiftAid::Data>] representing the donations of each member
    def self.get_data(api:, section:, term: nil, no_read_cache: false)
      Osm::Model.require_ability_to(api: api, to: :read, on: :finance, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['gift_aid_data', section_id, term_id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("giftaid.php?action=getGrid&sectionid=#{section_id}&termid=#{term_id}")

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
                  :tax_payer_name => item['parentname'],
                  :tax_payer_address => item['address'],
                  :tax_payer_postcode => item['postcode'],
                  :total => item['total'],
                  :donations => donations,
                )
              end
            end
          end # each item in data
        end # if
        to_return
      end # cache fetch
    end

    # Update information for a donation
    # @param api [Osm::Api] :api The api to use to make the request
    # @param section [Osm::Section] the section to update the donation for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to update the donation for
    # @param members [Integer, Array<Integer>, Osm::Member, Array<Osm::Member>, #to_i, Array<#to_i>] the members (or their ids) to update
    # @param date [Date, #strftime] date the date the donation was made
    # @param amount[String, #to_s] the donation amount
    # @param note [String, #to_s] the description for the donation
    # @return true, false whether the update succedded
    def self.update_donation(api:, section:, term: nil, members:, date: Date.today, amount:, note:)
      Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: section)
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      section_id = section.to_i

      members = [*members].map{ |member| member.to_i.to_s } # Make sure it's an Array of Strings

      response = api.post_query("giftaid.php?action=update&sectionid=#{section_id}&termid=#{term_id}", post_data: {
        'scouts' => members.inspect,
        'sectionid' => section_id,
        'donatedate'=> date.strftime(Osm::OSM_DATE_FORMAT),
        'amount' => amount,
        'notes' => note,
      })

      # The cached donations and data will be out of date - remove them
      Osm::Model.cache_delete(api: api, key: ['gift_aid_donations', section_id, term_id])
      Osm::Model.cache_delete(api: api, key: ['gift_aid_data', section_id, term_id])

      return response.is_a?(Array)
    end

    class Donation < Osm::Model
      # @!attribute [rw] donation_date
      #   @return [Date] When the payment was made

      attribute :donation_date, :type => Date

      validates_presence_of :donation_date


      # @!method initialize
      #   Initialize a new RegisterField
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      private def sort_by
        ['donation_date']
      end

    end # Class GiftAid::Donation


    class Data < Osm::Model
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
      # @!attribute [rw] tax_payer_name
      #   @return [String] The tax payer's name
      # @!attribute [rw] tax_payer_address
      #   @return [String] The tax payer's street address
      # @!attribute [rw] tax_payer_postcode
      #   @return [String] The tax payer's postcode
      # @!attribute [rw] total
      #   @return [String] Total
      # @!attribute [rw] donations
      #   @return [DirtyHashy] The data for each payment - keys are the date, values are the value of the payment

      attribute :member_id, :type => Integer
      attribute :grouping_id, :type => Integer
      attribute :section_id, :type => Integer
      attribute :first_name, :type => String
      attribute :last_name, :type => String
      attribute :tax_payer_name, :type => String
      attribute :tax_payer_address, :type => String
      attribute :tax_payer_postcode, :type => String
      attribute :total, :type => String
      attribute :donations, :type => Object, :default => DirtyHashy.new

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
      # @return true, false whether the data was updated in OSM
      # @raise [Osm::ObjectIsInvalid] If the Data is invalid
      def update(api)
        fail Osm::ObjectIsInvalid, 'data is invalid' unless valid?
        require_ability_to(api: api, to: :write, on: :finance, section: section_id)
        term_id = Osm::Term.get_current_term_for_section(api, section_id).id

        updated = true
        fields = [
          ['tax_payer_name', 'parentname', tax_payer_name],
          ['tax_payer_address', 'address', tax_payer_address],
          ['tax_payer_postcode', 'postcode', tax_payer_postcode],
        ]
        fields.each do |field|
          if changed_attributes.include?(field[0])
            result = api.post_query("giftaid.php?action=updateScout", post_data: {
              'scoutid' => member_id,
              'termid' => term_id,
              'column' => field[1],
              'value' => field[2],
              'sectionid' => section_id,
              'row' => 0,
            })
            if result.is_a?(Hash)
              (result['items'] || []).each do |i|
                if i['scoutid'] == member_id.to_s
                  updated = false unless i[field[1]] == field[2]
                end
              end
            end
          end
        end
        reset_changed_attributes if updated

        donations.changes.each do |date, (was,now)|
          date = date.strftime(Osm::OSM_DATE_FORMAT)
          result = api.post_query("giftaid.php?action=updateScout", post_data: {
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

        Osm::Model.cache_delete(api: api, key: ['gift_aid_data', section_id, term_id]) if updated

        return updated
      end

      private def sort_by
        ['section_id', 'grouping_id', 'last_name', 'first_name']
      end

    end # Class GiftAid::Data

  end # Class GiftAid

end
