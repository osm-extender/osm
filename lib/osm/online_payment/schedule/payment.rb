module Osm
  module OnlinePayment
    class Schedule < Osm::Model
      class Payment < Osm::Model
        # @!attribute [rw] id
        #   @return [FixNum] the payment's ID
        # @!attribute [rw] amount
        #   @return [Sreing] the amount of the payment
        # @!attribute [rw] name
        #   @return [String] the name given to the payment
        # @!attribute [rw] archived
        #   @return true, false whether the payment has been archived
        # @!attribute [rw] date
        #   @return [Date] the payment's due date
        # @!attribute [rw] schedule
        #   @return [Osm::OnlnePayment::Schedule] the schedule the payment belongs to

        attribute :id, type: Integer
        attribute :amount, type: String
        attribute :name, type: String
        attribute :archived, type: Boolean
        attribute :due_date, type: Object
        attribute :schedule, type: Object

        validates_numericality_of :id, only_integer: true, greater_than: 0
        validates_presence_of :amount
        validates_presence_of :name
        validates_presence_of :due_date
        validates_presence_of :schedule
        validates_inclusion_of :archived, in: [true, false]


        # @!method initialize
        #   Initialize a new Payment
        #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


        # Check if the payment is past due (or will be past due on the passed date)
        # @param date [Date] The date to check for (defaults to today)
        # @return true, false
        def past_due?(date=Date.today)
          date > due_date
        end

        def inspect
          Osm.inspect_instance(self, { replace_with: { 'schedule' => :to_s } })
        end

      end
    end
  end
end
