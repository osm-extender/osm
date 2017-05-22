# encoding: utf-8
require 'spec_helper'


describe "Invoice" do

  it "Create Invoice" do
    i = Osm::Invoice.new(
      id: 1,
      section_id: 2,
      name: 'Name',
      extra_details: 'Extra Details',
      date: Date.new(2001, 2, 3),
      archived: true,
      finalised: true,
    )

    expect(i.id).to eq(1)
    expect(i.section_id).to eq(2)
    expect(i.name).to eq('Name')
    expect(i.extra_details).to eq('Extra Details')
    expect(i.date).to eq(Date.new(2001, 2, 3))
    expect(i.archived).to eq(true)
    expect(i.finalised).to eq(true)
    expect(i.valid?).to eq(true)
  end

  it "Sorts Invoice by Section ID, Name then Date" do
    i1 = Osm::Invoice.new(section_id: 1, name: 'a', date: Date.new(2000, 1, 2))
    i2 = Osm::Invoice.new(section_id: 2, name: 'a', date: Date.new(2000, 1, 2))
    i3 = Osm::Invoice.new(section_id: 2, name: 'b', date: Date.new(2000, 1, 2))
    i4 = Osm::Invoice.new(section_id: 2, name: 'b', date: Date.new(2000, 1, 3))

    data = [i2, i4, i1, i3]
    expect(data.sort).to eq([i1, i2, i3, i4])
  end

  describe "Invoice Item" do
    it "Create" do
      ii = Osm::Invoice::Item.new(
        id: 1,
        invoice: Osm::Invoice.new,
        record_id: 3,
        date: Date.new(2002, 3, 4),
        amount: '5.00',
        type: :expense,
        payto: 'Name',
        description: 'Comments',
        budget_name: 'Budget',
      )
  
      expect(ii.id).to eq(1)
      expect(ii.invoice).to eq(Osm::Invoice.new)
      expect(ii.record_id).to eq(3)
      expect(ii.date).to eq(Date.new(2002, 3, 4))
      expect(ii.amount).to eq('5.00')
      expect(ii.type).to eq(:expense)
      expect(ii.payto).to eq('Name')
      expect(ii.description).to eq('Comments')
      expect(ii.budget_name).to eq('Budget')
      expect(ii.valid?).to eq(true)
    end
  
    it "Sorts by Invoice then Date" do
      i1 = Osm::Invoice.new(section_id: 1, name: 'a', date: Date.new(2000, 1, 2))
      i2 = Osm::Invoice.new(section_id: 2, name: 'a', date: Date.new(2000, 1, 2))
      ii1 = Osm::Invoice::Item.new(invoice: i1, date: Date.new(2000, 1, 1))
      ii2 = Osm::Invoice::Item.new(invoice: i2, date: Date.new(2000, 1, 1))
      ii3 = Osm::Invoice::Item.new(invoice: i2, date: Date.new(2000, 1, 2))
  
      data = [ii2, ii3, ii1]
      expect(data.sort).to eq([ii1, ii2, ii3])
    end

    it "Calculates value for easy summing" do
      expect(Osm::Invoice::Item.new(type: :income, amount: '1.00').value).to eq(1.00)
      expect(Osm::Invoice::Item.new(type: :expense, amount: '2.00').value).to eq(-2.00)
    end

  end


  describe "Using the API" do

    describe "Invoice" do

      describe "Get for section" do
        before :all do
          @invoices_body = {
            "identifier" => "invoiceid",
            "label" => "name",
            "items" => [
              {"invoiceid" => "1", "name" => "Invoice 1"},
              {"invoiceid" => "2", "name" => "Invoice 2"},
            ]
          }

          @invoice1_body = {
            "invoice" => {
              "invoiceid" => "1",
              "sectionid" => "3",
              "name" => "Invoice 1",
              "extra" => "Some more details",
              "entrydate" => "2010-01-01",
              "archived" => "0",
              "finalised" => "0"
            },
            "people" => [
              "Person 1",
              "Person 2",
              ""
            ],
            "categories" => [
              "Default",
              "A Budget"
            ]
          }
          @invoice2_body = {
            "invoice" => {
              "invoiceid" => "2",
              "sectionid" => "3",
              "name" => "Invoice 2",
              "extra" => "",
              "entrydate" => "2010-02-02",
              "archived" => "1",
              "finalised" => "1"
            },
            "people" => [
              "Person 1",
              "Person 2",
              ""
            ],
            "categories" => [
              "Default",
              "A Budget"
            ]
          }
        end

        it "From API" do
          expect($api).to receive(:post_query).with('finances.php?action=getInvoices&sectionid=3&showArchived=true').and_return(@invoices_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(@invoice1_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=2').and_return(@invoice2_body)

          invoices = Osm::Invoice.get_for_section(api: $api, section: 3)
          expect(invoices.size).to eq(1)
          invoice = invoices[0]
          expect(invoice.id).to eq(1)
          expect(invoice.section_id).to eq(3)
          expect(invoice.name).to eq('Invoice 1')
          expect(invoice.extra_details).to eq('Some more details')
          expect(invoice.date).to eq(Date.new(2010, 1, 1))
          expect(invoice.archived).to eq(false)
          expect(invoice.finalised).to eq(false)
          expect(invoice.valid?).to eq(true)
        end

        it "Honours archived option" do
          expect($api).to receive(:post_query).with('finances.php?action=getInvoices&sectionid=3&showArchived=true').and_return(@invoices_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(@invoice1_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=2').and_return(@invoice2_body)

          invoices = Osm::Invoice.get_for_section(api: $api, section: 3, include_archived: true)
          expect(invoices.size).to eq(2)
        end

        it "From Cache" do
          expect($api).to receive(:post_query).with('finances.php?action=getInvoices&sectionid=3&showArchived=true').and_return(@invoices_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(@invoice1_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=2').and_return(@invoice2_body)

          invoices = Osm::Invoice.get_for_section(api: $api, section: 3)
          expect($api).not_to receive(:post_query)
          expect(Osm::Invoice.get_for_section(api: $api, section: 3)).to eq(invoices)
        end

      end

      it "Get" do
        invoices_body = {
          "identifier" => "invoiceid",
          "label" => "name",
          "items" => [
            {"invoiceid" => "1", "name" => "Invoice 1"},
          ]
        }

        invoice1_body = {
          "invoice" => {
            "invoiceid" => "1",
            "sectionid" => "3",
            "name" => "Invoice 1",
            "extra" => "Some more details",
            "entrydate" => "2010-01-01",
            "archived" => "0",
            "finalised" => "0"
          },
          "people" => [
            "Person 1",
            "Person 2",
            ""
          ],
          "categories" => [
            "Default",
            "A Budget"
          ]
        }
        expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(invoice1_body)

        invoice = Osm::Invoice.get(api: $api, section: 3, id: 1)
        expect(invoice).not_to be_nil
        expect(invoice.id).to eq(1)
      end

      it "Create (success)" do
        invoice = Osm::Invoice.new(
          section_id: 1,
          name: 'Invoice name',
          extra_details: '',
          date: Date.new(2002, 3, 4),
        )

        expect($api).to receive(:post_query).with('finances.php?action=addInvoice&sectionid=1', post_data: {
          'name' => 'Invoice name',
          'extra' => '',
          'date' => '2002-03-04',
        }).and_return({"id"=>2})

        expect(invoice.create($api)).to eq(true)
        expect(invoice.id).to eq(2)
      end

      it "Create (failure)" do
        invoice = Osm::Invoice.new(
          section_id: 1,
          name: 'Invoice name',
          extra_details: '',
          date: Date.new(2002, 3, 4),
        )

        expect($api).to receive(:post_query).with('finances.php?action=addInvoice&sectionid=1', post_data: {
          'name' => 'Invoice name',
          'extra' => '',
          'date' => '2002-03-04',
        }).and_return({"message"=>"Something went wrong"})

        expect(invoice.create($api)).to eq(false)
        expect(invoice.id).to be_nil
      end

      it "Update (success)" do
        invoice = Osm::Invoice.new(
          id: 1,
          section_id: 2,
          name: 'Invoice name',
          extra_details: '',
          date: Date.new(2002, 3, 4),
        )

        expect($api).to receive(:post_query).with('finances.php?action=addInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'name' => 'Invoice name',
          'extra' => '',
          'date' => '2002-03-04',
        }).and_return({"ok"=>true})

        expect(invoice.update($api)).to eq(true)
      end

      it "Update (failure)" do
        invoice = Osm::Invoice.new(
          id: 1,
          section_id: 2,
          name: 'Invoice name',
          extra_details: '',
          date: Date.new(2002, 3, 4),
        )

        expect($api).to receive(:post_query).with('finances.php?action=addInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'name' => 'Invoice name',
          'extra' => '',
          'date' => '2002-03-04',
        }).and_return({"ok"=>false})

        expect(invoice.update($api)).to eq(false)
      end

      it "Delete (success)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
        }).and_return({"ok"=>true})

        expect(invoice.delete($api)).to eq(true)
      end

      it "Delete (failure)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
        }).and_return({"ok"=>false})

        expect(invoice.delete($api)).to eq(false)
      end

      it "Finalise invoice (success)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=finaliseInvoice&sectionid=2&invoiceid=1').and_return({"ok"=>true})

        expect(invoice.finalise($api)).to eq(true)
        expect(invoice.finalised).to eq(true)
      end

      it "Finalise invoice (failure)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=finaliseInvoice&sectionid=2&invoiceid=1').and_return({"ok"=>false})

        expect(invoice.finalise($api)).to eq(false)
        expect(invoice.finalised).to eq(false)
      end

      it "Finalise invoice (already finalised)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2, finalised: true)

        expect($api).not_to receive(:post_query)

        expect(invoice.finalise($api)).to eq(false)
        expect(invoice.finalised).to eq(true)
      end

      it "Archive invoice (success)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'archived' => 1,
        }).and_return({"ok"=>true})

        expect(invoice.archive($api)).to eq(true)
        expect(invoice.archived).to eq(true)
      end

      it "Archive invoice (failure)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'archived' => 1,
        }).and_return({"ok"=>false})

        expect(invoice.archive($api)).to eq(false)
        expect(invoice.archived).to eq(false)
      end

      it "Archive invoice (already archived)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2, archived: true)

        expect($api).not_to receive(:post_query)

        expect(invoice.archive($api)).to eq(false)
        expect(invoice.archived).to eq(true)
      end

    end


    describe "Item" do

      it "Get for invoice" do
        data = {"identifier" => "id","items" => [
          {"id" => "1","invoiceid" => "2","recordid" => "3","sectionid" => "4","entrydate" => "2012-01-02","amount" => "1.23","type" => "Expense","payto_userid" => "John Smith","comments" => "Comment","categoryid" => "Default","firstname" => "John Smith"}
        ]}
        expect($api).to receive(:post_query).with('finances.php?action=getInvoiceRecords&invoiceid=2&sectionid=4&dateFormat=generic').and_return(data)

        invoice = Osm::Invoice.new(id: 2, section_id: 4)
        items = invoice.get_items($api)
        expect(items.size).to eq(1)
        item = items[0]
        expect(item.id).to eq(1)
        expect(item.invoice).to eq(invoice)
        expect(item.record_id).to eq(3)
        expect(item.date).to eq(Date.new(2012, 1, 2))
        expect(item.amount).to eq('1.23')
        expect(item.type).to eq(:expense)
        expect(item.payto).to eq('John Smith')
        expect(item.budget_name).to eq('Default')
        expect(item.description).to eq('Comment')
        expect(item.valid?).to eq(true)
      end

      it "Create (success)" do
        invoice = Osm::Invoice.new(id: 3, section_id: 2)
        item = Osm::Invoice::Item.new(
          invoice: invoice,
          amount: '1.23',
          type: :expense,
          budget_name: 'A budget',
          date: Date.new(2003, 5, 6),
          description: 'A description',
          payto: 'Person to Pay',
        )

        expect($api).to receive(:post_query).with('finances.php?action=addRecord&invoiceid=3&sectionid=2').and_return({"ok"=>true})

        data1 = [
          Osm::Invoice::Item.new(id: 1, invoice: invoice, record_id: 3, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => 'Comment', :budget_name => 'Default'),
        ]
        data2 = [
          Osm::Invoice::Item.new(id: 1, invoice: invoice, record_id: 3, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => 'Comment', :budget_name => 'Default'),
          Osm::Invoice::Item.new(id: 2, invoice: invoice, record_id: 4, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => '', :budget_name => 'Default'),
        ]
        expect(invoice).to receive(:get_items).with($api, no_read_cache: true).and_return(data1, data2)

        [
          # osm_name, new_value
          ['amount', '1.23'],
          ['comments', 'A description'],
          ['type', 'Expense'],
          ['payto_userid', 'Person to Pay'],
          ['categoryid', 'A budget'],
          ['entrydate', '2003-05-06'],
        ].each do |osm_name, new_value|
          expect($api).to receive(:post_query).with('finances.php?action=updateRecord&sectionid=2&dateFormat=generic', post_data: {
            'section_id' => 2,
            'invoiceid' => 3,
            'recordid' => 4,
            'row' => 0,
            'column' => osm_name,
            'value' => new_value,
          }).and_return({osm_name => new_value})
        end

        expect(item.create($api)).to eq(true)
        expect(item.id).to eq(2)
        expect(item.record_id).to eq(4)
      end

      it "Create (failure to create)" do
        invoice = Osm::Invoice.new(id: 3, section_id: 2)
        item = Osm::Invoice::Item.new(
          invoice: invoice,
          amount: '1.23',
          type: :expense,
          budget_name: 'A budget',
          date: Date.new(2003, 5, 6),
          description: 'A description',
          payto: 'Person to Pay',
        )

        expect($api).to receive(:post_query).with('finances.php?action=addRecord&invoiceid=3&sectionid=2').and_return({"ok"=>false})

        data = [
          Osm::Invoice::Item.new(id: 1, invoice: invoice, record_id: 3, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => 'Comment', :budget_name => 'Default'),
        ]
        expect(invoice).to receive(:get_items).with($api, no_read_cache: true).and_return(data)

        expect(item.create($api)).to eq(false)
      end

      it "Update (success)" do
        item = Osm::Invoice::Item.new(
          id: 1,
          invoice: Osm::Invoice.new(id: 3, section_id: 2),
          record_id: 4,
        )
        item.amount = '1.23'
        item.type = :income
        item.budget_name = 'A different budget'
        item.date = Date.new(2003, 5, 6)
        item.description = 'A new description'
        item.payto = 'Another person to Pay'

        [
          # osm_name, new_value
          ['amount', '1.23'],
          ['comments', 'A new description'],
          ['type', 'Income'],
          ['payto_userid', 'Another person to Pay'],
          ['categoryid', 'A different budget'],
          ['entrydate', '2003-05-06'],
        ].each do |osm_name, new_value|
          expect($api).to receive(:post_query).with('finances.php?action=updateRecord&sectionid=2&dateFormat=generic', post_data: {
            'section_id' => 2,
            'invoiceid' => 3,
            'recordid' => 4,
            'row' => 0,
            'column' => osm_name,
            'value' => new_value,
          }).and_return({osm_name => new_value})
        end

        expect(item.update($api)).to eq(true)
      end

      it "Update (failure)" do
        item = Osm::Invoice::Item.new(
          id: 1,
          invoice: Osm::Invoice.new(id: 3, section_id: 2),
          record_id: 4,
          amount: '1.23',
          type: :expense,
          budget_name: 'A budget',
          date: Date.new(2003, 4, 5),
          description: 'A description',
          payto: 'Person to Pay',
        )
        item.description = 'A new description'

        expect($api).to receive(:post_query).with('finances.php?action=updateRecord&sectionid=2&dateFormat=generic', post_data: {
          'section_id' => 2,
          'invoiceid' => 3,
          'recordid' => 4,
          'row' => 0,
          'column' => 'comments',
          'value' => 'A new description',
        }).and_return({"comments"=>"A description"})

        expect(item.update($api)).to eq(false)
      end

      it "Delete (success)" do
        item = Osm::Invoice::Item.new(id: 1, invoice: Osm::Invoice.new(id: 3, section_id: 2))

        expect($api).to receive(:post_query).with('finances.php?action=deleteEntry&sectionid=2', post_data: {
          'id' => 1,
        }).and_return({"ok"=>true})

        expect(item.delete($api)).to eq(true)
      end

      it "Delete (failure)" do
        item = Osm::Invoice::Item.new(id: 1, invoice: Osm::Invoice.new(id: 2, section_id: 4),)

        expect($api).to receive(:post_query).with('finances.php?action=deleteEntry&sectionid=4', post_data: {
          'id' => 1,
        }).and_return({"ok"=>false})

        expect(item.delete($api)).to eq(false)
      end

    end

  end

end
