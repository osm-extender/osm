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
                donation_date: Osm.parse_date(row['field'])
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
            next unless item.is_a?(Hash)
            unless item['scoutid'].to_i < 0  # It's a total row
              donations = {}
              item.each do |key, value|
                if key.match(Osm::OSM_DATE_REGEX)
                  donations[Osm.parse_date(key)] = value
                end
              end
              to_return.push Osm::GiftAid::Data.new(
                member_id: Osm.to_i_or_nil(item['scoutid']),
                grouping_id: Osm.to_i_or_nil(item ['patrolid']),
                section_id: section_id,
                first_name: item['firstname'],
                last_name: item['lastname'],
                tax_payer_name: item['parentname'],
                tax_payer_address: item['address'],
                tax_payer_postcode: item['postcode'],
                total: item['total'],
                donations: donations
              )
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

      response.is_a?(Array)
    end

  end
end
