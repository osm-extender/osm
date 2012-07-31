module Osm

  class DueBadges

    attr_reader :descriptions, :by_member, :totals

    # Initialize a new Event using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      data = {} unless data.is_a?(Hash)

      @pending = Osm::symbolize_hash(data['pending'] || {})
      @descriptions = Osm::symbolize_hash(data['description'] || {})

      @pending.each_key do |key|
        @pending[key].each_with_index do |item, index|
          @pending[key][index] = item = Osm::symbolize_hash(item)
          item[:sid] = item[:sid].to_i
          item[:completed] = item[:completed].to_i
        end
      end
      @descriptions.each_key do |key|
        @descriptions[key] = Osm::symbolize_hash(@descriptions[key])
        @descriptions[key][:section] = @descriptions[key][:section].to_sym
        @descriptions[key][:type] = @descriptions[key][:type].to_sym
      end


      @by_member = {}
      @totals = {}
      @pending.each_key do |key|
        @pending[key].each do |item|
          name = "#{item[:firstname]} #{item[:lastname]}"
          by_member[name] = [] if by_member[name].nil?

          badge = {
            :badge => key,
            :extra_information => item[:extra]
          }
          by_member[name].push badge
          @totals[key] = {} if @totals[key].nil?
          @totals[key][item[:extra]] = @totals[key][item[:extra]].to_i + 1
        end
      end
    end

    def empty?
      return @by_member.empty?
    end

  end

end
