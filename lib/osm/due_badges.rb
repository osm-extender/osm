module Osm

  class DueBadges

    attr_reader :descriptions, :by_member, :totals
    # @!attribute [r] descriptions
    #   @return [Hash] descriptions for each of the badges
    # @!attribute [r] by_member
    #   @return [Hash] the due badges grouped by member
    # @!attribute [r] totals
    #   @return [Hash] the total number of each badge which is due

    # Initialize a new DueBadges
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      [:descriptions, :by_member, :totals].each do |attribute|
        raise ArgumentError, ":#{attribute} must be a Hash" unless attributes[attribute].is_a?(Hash)
      end

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }
    end


    # Initialize a new DueBadges from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      data = {} unless data.is_a?(Hash)
      attributes = {}

      attributes[:pending] = data['pending'].is_a?(Hash) ? Osm::symbolize_hash(data['pending']) : {}
      attributes[:descriptions] = data['description'].is_a?(Hash) ? Osm::symbolize_hash(data['description']) : {}

      attributes[:pending].each_key do |key|
        attributes[:pending][key].each_with_index do |item, index|
          attributes[:pending][key][index] = item = Osm::symbolize_hash(item)
          item[:sid] = item[:sid].to_i
          item[:completed] = item[:completed].to_i
        end
      end
      attributes[:descriptions].each_key do |key|
        attributes[:descriptions][key] = Osm::symbolize_hash(attributes[:descriptions][key])
        attributes[:descriptions][key][:section] = attributes[:descriptions][key][:section].to_sym
        attributes[:descriptions][key][:type] = attributes[:descriptions][key][:type].to_sym
      end


      attributes[:by_member] = {}
      attributes[:totals] = {}
      attributes[:pending].each_key do |key|
        attributes[:pending][key].each do |item|
          name = "#{item[:firstname]} #{item[:lastname]}"
          attributes[:by_member][name] = [] if attributes[:by_member][name].nil?

          badge = {
            :badge => key,
            :extra_information => item[:extra]
          }
          attributes[:by_member][name].push badge
          attributes[:totals][key] = {} if attributes[:totals][key].nil?
          attributes[:totals][key][item[:extra]] = attributes[:totals][key][item[:extra]].to_i + 1
        end
      end
      
      new(attributes)
    end

    # Check if there are no badges due
    # @return [Boolean]
    def empty?
      return @by_member.empty?
    end

  end # Class

end # Module
