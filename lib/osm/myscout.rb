module Osm

  class Myscout

    class ParentLoginHistory < Osm::Model
      SORT_BY= [:last_name, :first_name, :member_id]

      # @!attribute [rw] member_id
      #   @return [Fixnum] the id for the member
      # @!attribute [rw] first_name
      #   @return [String] the member's first name
      # @!attribute [rw] last_name
      #   @return [String] the member's last name
      # @!attribute [rw] logins
      #   @return [Fixnum] the total number of logins
      # @!attribute [rw] last_login
      #   @return [DateTime] the time and date of the last login

      attribute :member_id, type: Integer
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :logins, type: Integer
      attribute :last_login, type: DateTime

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :member_id, :first_name, :last_name, :logins, :last_login
      end

      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_numericality_of :member_id, only_integer: true, greater_than: 0
      validates_numericality_of :logins, only_integer: true, greater_than_or_equal_to: 0


      # @!method initialize
      #   Initialize a new Member
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Get parent login history
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get login history for
      # @!macro options_get
      # @return [Array<Osm::Myscout::ParentLoginHistory>]
      def self.get_for_section(api, section, options={})
        section_id = section.to_i
        require_ability_to(api, :read, :member, section, options)
        cache_key = ['myscout', 'parent_login_history', section_id]

        if !options[:no_cache] && cache_exist?(api, cache_key)
          return cache_read(api, cache_key)
        end

        data = api.perform_query("ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=#{section_id}")
        return [] unless data.is_a?(Hash)
        data = data['items']
        return [] unless data.is_a?(Array)

        data.map! do |item|
          new(
            member_id:    Osm::to_i_or_nil(item['scoutid']),
            first_name:   item['firstname'],
            last_name:    item['lastname'],
            logins:       Osm::to_i_or_nil(item['numlogins']),
            last_login:   get_last_login_date(item['lastlogin'],)
          )
        end

        cache_write(api, cache_key, data)
        return data
      end

      private
      def self.get_last_login_date(date_str)
        return nil if date_str.nil?
        return nil if date_str.eql?('Invitation not sent')
        Time.strptime(date_str, '%d/%m/%Y %H:%M')
      end

    end # class Myscout::ParentLoginHistory

  end
   
end
