module OSM
  class GiftAid
    class Donation < OSM::Model
      # @!attribute [rw] donation_date
      #   @return [Date] When the payment was made

      attribute :donation_date, type: Date

      validates_presence_of :donation_date


      # @!method initialize
      #   Initialize a new RegisterField
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      private def sort_by
        ['donation_date']
      end

    end
  end
end
