module OSM
  class Badge
    class StagedActivity < OSM::Badge

      def self.type
        :staged
      end

      def self.type_id
        3
      end

    end
  end
end
