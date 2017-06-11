module Osm
  class StagedBadge < Osm::Badge

    private

    def self.type
      :staged
    end

    def self.type_id
      3
    end

  end
end
