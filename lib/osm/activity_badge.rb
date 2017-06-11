module Osm
  class ActivityBadge < Osm::Badge

    private

    def self.type
      :activity
    end

    def self.type_id
      2
    end

    def self.subscription_required
      :silver
    end

  end
end
