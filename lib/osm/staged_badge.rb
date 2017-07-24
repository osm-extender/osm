module OSM
  class StagedBadge < OSM::Badge

    def self.type
      :staged
    end

    def self.type_id
      3
    end

  end
end
