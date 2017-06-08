module Osm
  class Invoice < Osm::Model
    # @!attribute [rw] id
    #   @return [Integer] The OSM ID for the invoice
    # @!attribute [rw] section_id
    #   @return [Integer] The OSM ID for the section the invoice belongs to
    # @!attribute [rw] name
    #   @return [String] The name given to the invoice
    # @!attribute [rw] extra_details
    #   @return [String] Any extra details added to the invoice
    # @!attribute [rw] date
    #   @return [Date] When the invoice was created
    # @!attribute [rw] archived
    #   @return true, false Whether the invoice has been archived
    # @!attribute [rw] finalised
    #   @return true, false Whether the invoice has been finalised

    attribute :id, type: Integer
    attribute :section_id, type: Integer
    attribute :name, type: String
    attribute :extra_details, type: String, default: ''
    attribute :date, type: Date, default: Date.today
    attribute :archived, type: Boolean, default: false
    attribute :finalised, type: Boolean, default: false

    validates_numericality_of :id, only_integer:true, greater_than:0, unless: Proc.new { |r| r.id.nil? }
    validates_numericality_of :section_id, only_integer:true, greater_than:0
    validates_presence_of :name
    validates_presence_of :date
    validates_inclusion_of :archived, in: [true, false]
    validates_inclusion_of :finalised, in: [true, false]


    # @!method initialize
    #   Initialize a new Budget
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get invoices for a section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the invoices for
    # @!macro options_get
    # @option options true, false :include_archived (optional) if true then archived invoices will also be returned
    # @return [Array<Osm::Invoice>]
    def self.get_for_section(api:, section:, include_archived: false, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :finance, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      cache_key = ['invoice_ids', section_id]
      invoices = nil

      if cache_exist?(api: api, key: cache_key, no_read_cache: no_read_cache)
        ids = cache_read(api: api, key: cache_key)
        invoices = get_from_ids(api: api, ids: ids, key_base: 'invoice', arguments: [section], method: :get_for_section, no_read_cache: no_read_cache)
      end

      if invoices.nil?
        data = api.post_query("finances.php?action=getInvoices&sectionid=#{section_id}&showArchived=true")
        invoices = Array.new
        ids = Array.new
        unless data['items'].nil?
          data['items'].map { |i| i['invoiceid'].to_i }.each do |invoice_id|
            invoice_data = api.post_query("finances.php?action=getInvoice&sectionid=#{section_id}&invoiceid=#{invoice_id}")
            invoice = self.new_invoice_from_data(invoice_data)
            invoices.push invoice
            ids.push invoice.id
            cache_write(api: api, key: ['invoice', invoice.id], data: invoice)
          end
        end
        cache_write(api: api, key: cache_key, data: ids)
      end

      return invoices if include_archived
      return invoices.reject do |invoice|
        invoice.archived?
      end
    end

    # Get an invoice
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the events for
    # @param id [Integer, #to_i] The id of the invoice to get
    # @!macro options_get
    # @return [Osm::Invoice, nil] the invoice (or nil if it couldn't be found
    def self.get(api:, section:, id:, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :events, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      invoice_id = invoice_id.to_i
      cache_key = ['invoice', id]

      if cache_exist?(api: api, key: cache_key, no_read_cache: no_read_cache)
        return cache_read(api: api, key: cache_key)
      end

      invoice_data = api.post_query("finances.php?action=getInvoice&sectionid=#{section_id}&invoiceid=#{id}")
      return self.new_invoice_from_data(invoice_data)
    end


    # Create the invoice in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return true, false Whether the invoice was created in OSM
    # @raise [Osm::ObjectIsInvalid] If the Invoice is invalid
    # @raise [Osm::Error] If the invoice already exists in OSM
    def create(api)
      fail Osm::Error, 'the invoice already exists in OSM' unless id.nil?
      fail Osm::ObjectIsInvalid, 'invoice is invalid' unless valid?
      Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: section_id)

      data = api.post_query("finances.php?action=addInvoice&sectionid=#{section_id}", post_data: {
        'name' => name,
        'extra' => extra_details,
        'date' => date.strftime(Osm::OSM_DATE_FORMAT),
      })
      if data.is_a?(Hash) && !data['id'].nil?
        # The cached invoices for the section will be out of date - remove them
        cache_delete(api: api, key: ['invoice_ids', section_id])
        self.id = data['id'].to_i
        return true
      end
      return false
    end

    # Update the invoice in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return [Boolan] whether the invoice was successfully updated or not
    # @raise [Osm::ObjectIsInvalid] If the Invoice is invalid
    def update(api)
      fail Osm::ObjectIsInvalid, 'invoice is invalid' unless valid?
      require_ability_to(api: api, to: :write, on: :finance, section: section_id)

      data = api.post_query("finances.php?action=addInvoice&sectionid=#{section_id}", post_data: {
        'invoiceid' => id,
        'name' => name,
        'extra' => extra_details,
        'date' => date.strftime(Osm::OSM_DATE_FORMAT),
      })

      if data.is_a?(Hash) && data['ok'].eql?(true)
        reset_changed_attributes
        # The cached invoice will be out of date - remove it
        cache_delete(api: api, key: ['invoice', self.id])
        return true
      end
      return false
    end

    # Delete the invoice from OSM
    # @param api [Osm::Api] The api to use for the query
    # @return true, false Whether the invoice was deleted from OSM
    def delete(api)
      Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: section_id)
      return false if finalised?

      data = api.post_query("finances.php?action=deleteInvoice&sectionid=#{section_id}", post_data: {
        'invoiceid' => id,
      })
      if (data.is_a?(Hash) && data['ok'].eql?(true))
        # The cached invoices for the section will be out of date - remove them
        cache_delete(api: api, key: ['invoice_ids', section_id])
        cache_delete(api: api, key: ['invoice', self.id])
        return true
      end
      return false
    end

    # Archive the invoice in OSM, updating the archived attribute if successful.
    # If the archived attribute is true then nothing happens and false is returned.
    # @param api [Osm::Api] The api to use for the request
    # @return true, false Whether the invoice was archived in OSM
    # @raise [Osm::Error] If the invoice does not already exist in OSM
    def archive(api)
      Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: section_id)
      fail Osm::Error, 'the invoice does not already exist in OSM' if id.nil?
      return false if archived?

      data = api.post_query("finances.php?action=deleteInvoice&sectionid=#{section_id}", post_data: {
        'invoiceid' => id,
        'archived' => 1,
      })
      if (data.is_a?(Hash) && data['ok'].eql?(true))
        self.archived = true
        # The cached invoice for the section will be out of date - remove it
        cache_delete(api: api, key: ['invoice', self.id])
        return true
      end
      return false
    end

    # Finalise the invoice in OSM, updating the finalised attribute if successful.
    # If the finalised attribute is true then nothing happens and false is returned.
    # @param api [Osm::Api] The api to use for the query
    # @return true, false Whether the invoice was finalised in OSM
    # @raise [Osm::Error] If the invoice does not already exist in OSM
    def finalise(api)
      Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: section_id)
      fail Osm::Error, 'the invoice does not already exist in OSM' if id.nil?
      return false if finalised?

      data = api.post_query("finances.php?action=finaliseInvoice&sectionid=#{section_id}&invoiceid=#{id}")
      if (data.is_a?(Hash) && data['ok'].eql?(true))
        self.finalised = true
        # The cached invoice for the section will be out of date - remove it
        cache_delete(api: api, key: ['invoice', self.id])
        return true
      end
      return false
    end

    # Get items for the invoice
    # @param api [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return [Array<Osm::Invoice::Item>]
    def get_items(api, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :finance, section: section_id, no_read_cache: no_read_cache)
      cache_key = ['invoice_items', id]

      items = cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("finances.php?action=getInvoiceRecords&invoiceid=#{id}&sectionid=#{section_id}&dateFormat=generic")
        data['items'].map do |item|
          Osm::Invoice::Item.new(
            id: Osm::to_i_or_nil(item['id']),
            invoice: self,
            record_id: Osm::to_i_or_nil(item['recordid']),
            date: Osm::parse_date(item['entrydate']),
            amount: item['amount'],
            type: item['type'].to_s.downcase.to_sym,
            payto: item['payto_userid'].to_s.strip,
            description: item['comments'],
            budget_name: item['categoryid'],
          )
        end
      end # cache fetch

      cache_write(api: api, key: cache_key, data: items)
      return items
    end


    private
    def self.new_invoice_from_data(invoice_data)
      invoice_data = invoice_data['invoice']
      return nil unless invoice_data.is_a?(Hash)
      Osm::Invoice.new(
        id: Osm::to_i_or_nil(invoice_data['invoiceid']),
        section_id: Osm::to_i_or_nil(invoice_data['sectionid']),
        name: invoice_data['name'],
        extra_details: invoice_data['extra'],
        date: Osm::parse_date(invoice_data['entrydate']),
        archived: invoice_data['archived'].eql?('1'),
        finalised: invoice_data['finalised'].eql?('1'),
      )
    end

    def sort_by
      ['section_id', 'name', 'date']
    end

  end
end
