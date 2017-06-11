module Osm
  class ChallengeBadge < Osm::Badge

    def self.type
      :challenge
    end

    def self.type_id
      1
    end

  end
end
