module Osm
  class CoreBadge < Osm::Badge

    private
    def self.type
      :core
    end

    def self.type_id
      4
    end

  end
end
