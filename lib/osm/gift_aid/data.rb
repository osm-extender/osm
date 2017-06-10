module Osm
  class GiftAid
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

      attribute :member_id, type: Integer
      attribute :grouping_id, type: Integer
      attribute :section_id, type: Integer
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :tax_payer_name, type: String
      attribute :tax_payer_address, type: String
      attribute :tax_payer_postcode, type: String
      attribute :total, type: String
      attribute :donations, type: Object, default: DirtyHashy.new

      validates_numericality_of :member_id, only_integer: true, greater_than: 0
      validates_numericality_of :grouping_id, only_integer: true, greater_than_or_equal_to: -2
      validates_numericality_of :section_id, only_integer: true, greater_than: 0
      validates_presence_of :first_name
      validates_presence_of :last_name

      validates :donations, hash: {key_type: Date, value_type: String}


      # @!method initialize
      #   Initialize a new registerData
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      # Override initialize to set @orig_attributes
      old_initialize = instance_method(:initialize)
      define_method :initialize do |*args|
        ret_val = old_initialize.bind(self).call(*args)
        self.donations = DirtyHashy.new(donations)
        donations.clean_up!
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
            result = api.post_query('giftaid.php?action=updateScout', post_data: {
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
          result = api.post_query('giftaid.php?action=updateScout', post_data: {
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

        updated
      end

      private def sort_by
        ['section_id', 'grouping_id', 'last_name', 'first_name']
      end

    end
  end
end
