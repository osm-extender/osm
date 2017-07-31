module OSM
  class Badge
    class Challenge < OSM::Badge

      def self.type
        :challenge
      end

      def self.type_id
        1
      end

    end
  end
end
