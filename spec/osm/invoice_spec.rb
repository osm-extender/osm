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

    i.id.should == 1
    i.section_id.should == 2
    i.name.should == 'Name'
    i.extra_details.should == 'Extra Details'
    i.date.should == Date.new(2001, 2, 3)
    i.archived.should == true
    i.finalised.should == true
    i.valid?.should == true
  end

  it "Sorts Invoice by Section ID, Name then Date" do
    i1 = Osm::Invoice.new(section_id: 1, name: 'a', date: Date.new(2000, 1, 2))
    i2 = Osm::Invoice.new(section_id: 2, name: 'a', date: Date.new(2000, 1, 2))
    i3 = Osm::Invoice.new(section_id: 2, name: 'b', date: Date.new(2000, 1, 2))
    i4 = Osm::Invoice.new(section_id: 2, name: 'b', date: Date.new(2000, 1, 3))

    data = [i2, i4, i1, i3]
    data.sort.should == [i1, i2, i3, i4]
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
  
      ii.id.should == 1
      ii.invoice.should == Osm::Invoice.new
      ii.record_id.should == 3
      ii.date.should == Date.new(2002, 3, 4)
      ii.amount.should == '5.00'
      ii.type.should == :expense
      ii.payto.should == 'Name'
      ii.description.should == 'Comments'
      ii.budget_name.should == 'Budget'
      ii.valid?.should == true
    end
  
    it "Sorts by Invoice then Date" do
      i1 = Osm::Invoice.new(section_id: 1, name: 'a', date: Date.new(2000, 1, 2))
      i2 = Osm::Invoice.new(section_id: 2, name: 'a', date: Date.new(2000, 1, 2))
      ii1 = Osm::Invoice::Item.new(invoice: i1, date: Date.new(2000, 1, 1))
      ii2 = Osm::Invoice::Item.new(invoice: i2, date: Date.new(2000, 1, 1))
      ii3 = Osm::Invoice::Item.new(invoice: i2, date: Date.new(2000, 1, 2))
  
      data = [ii2, ii3, ii1]
      data.sort.should == [ii1, ii2, ii3]
    end

    it "Calculates value for easy summing" do
      Osm::Invoice::Item.new(type: :income, amount: '1.00').value.should == 1.00
      Osm::Invoice::Item.new(type: :expense, amount: '2.00').value.should == -2.00
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
          $api.should_receive(:post_query).with('finances.php?action=getInvoices&sectionid=3&showArchived=true').and_return(@invoices_body)
          $api.should_receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(@invoice1_body)
          $api.should_receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=2').and_return(@invoice2_body)

          invoices = Osm::Invoice.get_for_section(api: $api, section: 3)
          invoices.size.should == 1
          invoice = invoices[0]
          invoice.id.should == 1
          invoice.section_id.should == 3
          invoice.name.should == 'Invoice 1'
          invoice.extra_details.should == 'Some more details'
          invoice.date.should == Date.new(2010, 1, 1)
          invoice.archived.should == false
          invoice.finalised.should == false
          invoice.valid?.should == true
        end

        it "Honours archived option" do
          $api.should_receive(:post_query).with('finances.php?action=getInvoices&sectionid=3&showArchived=true').and_return(@invoices_body)
          $api.should_receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(@invoice1_body)
          $api.should_receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=2').and_return(@invoice2_body)

          invoices = Osm::Invoice.get_for_section(api: $api, section: 3, include_archived: true)
          invoices.size.should == 2
        end

        it "From Cache" do
          $api.should_receive(:post_query).with('finances.php?action=getInvoices&sectionid=3&showArchived=true').and_return(@invoices_body)
          $api.should_receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(@invoice1_body)
          $api.should_receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=2').and_return(@invoice2_body)

          invoices = Osm::Invoice.get_for_section(api: $api, section: 3)
          $api.should_not_receive(:post_query)
          Osm::Invoice.get_for_section(api: $api, section: 3).should == invoices
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
        $api.should_receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(invoice1_body)

        invoice = Osm::Invoice.get(api: $api, section: 3, id: 1)
        invoice.should_not be_nil
        invoice.id.should == 1
      end

      it "Create (success)" do
        invoice = Osm::Invoice.new(
          section_id: 1,
          name: 'Invoice name',
          extra_details: '',
          date: Date.new(2002, 3, 4),
        )

        $api.should_receive(:post_query).with('finances.php?action=addInvoice&sectionid=1', post_data: {
          'name' => 'Invoice name',
          'extra' => '',
          'date' => '2002-03-04',
        }).and_return({"id"=>2})

        invoice.create($api).should == true
        invoice.id.should == 2
      end

      it "Create (failure)" do
        invoice = Osm::Invoice.new(
          section_id: 1,
          name: 'Invoice name',
          extra_details: '',
          date: Date.new(2002, 3, 4),
        )

        $api.should_receive(:post_query).with('finances.php?action=addInvoice&sectionid=1', post_data: {
          'name' => 'Invoice name',
          'extra' => '',
          'date' => '2002-03-04',
        }).and_return({"message"=>"Something went wrong"})

        invoice.create($api).should == false
        invoice.id.should be_nil
      end

      it "Update (success)" do
        invoice = Osm::Invoice.new(
          id: 1,
          section_id: 2,
          name: 'Invoice name',
          extra_details: '',
          date: Date.new(2002, 3, 4),
        )

        $api.should_receive(:post_query).with('finances.php?action=addInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'name' => 'Invoice name',
          'extra' => '',
          'date' => '2002-03-04',
        }).and_return({"ok"=>true})

        invoice.update($api).should == true
      end

      it "Update (failure)" do
        invoice = Osm::Invoice.new(
          id: 1,
          section_id: 2,
          name: 'Invoice name',
          extra_details: '',
          date: Date.new(2002, 3, 4),
        )

        $api.should_receive(:post_query).with('finances.php?action=addInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'name' => 'Invoice name',
          'extra' => '',
          'date' => '2002-03-04',
        }).and_return({"ok"=>false})

        invoice.update($api).should == false
      end

      it "Delete (success)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        $api.should_receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
        }).and_return({"ok"=>true})

        invoice.delete($api).should == true
      end

      it "Delete (failure)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        $api.should_receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
        }).and_return({"ok"=>false})

        invoice.delete($api).should == false
      end

      it "Finalise invoice (success)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        $api.should_receive(:post_query).with('finances.php?action=finaliseInvoice&sectionid=2&invoiceid=1').and_return({"ok"=>true})

        invoice.finalise($api).should == true
        invoice.finalised.should == true
      end

      it "Finalise invoice (failure)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        $api.should_receive(:post_query).with('finances.php?action=finaliseInvoice&sectionid=2&invoiceid=1').and_return({"ok"=>false})

        invoice.finalise($api).should == false
        invoice.finalised.should == false
      end

      it "Finalise invoice (already finalised)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2, finalised: true)

        $api.should_not_receive(:post_query)

        invoice.finalise($api).should == false
        invoice.finalised.should == true
      end

      it "Archive invoice (success)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        $api.should_receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'archived' => 1,
        }).and_return({"ok"=>true})

        invoice.archive($api).should == true
        invoice.archived.should == true
      end

      it "Archive invoice (failure)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        $api.should_receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'archived' => 1,
        }).and_return({"ok"=>false})

        invoice.archive($api).should == false
        invoice.archived.should == false
      end

      it "Archive invoice (already archived)" do
        invoice = Osm::Invoice.new(id: 1, section_id: 2, archived: true)

        $api.should_not_receive(:post_query)

        invoice.archive($api).should == false
        invoice.archived.should == true
      end

    end


    describe "Item" do

      it "Get for invoice" do
        data = {"identifier" => "id","items" => [
          {"id" => "1","invoiceid" => "2","recordid" => "3","sectionid" => "4","entrydate" => "2012-01-02","amount" => "1.23","type" => "Expense","payto_userid" => "John Smith","comments" => "Comment","categoryid" => "Default","firstname" => "John Smith"}
        ]}
        $api.should_receive(:post_query).with('finances.php?action=getInvoiceRecords&invoiceid=2&sectionid=4&dateFormat=generic').and_return(data)

        invoice = Osm::Invoice.new(id: 2, section_id: 4)
        items = invoice.get_items($api)
        items.size.should == 1
        item = items[0]
        item.id.should == 1
        item.invoice.should == invoice
        item.record_id.should == 3
        item.date.should == Date.new(2012, 1, 2)
        item.amount.should == '1.23'
        item.type.should == :expense
        item.payto.should == 'John Smith'
        item.budget_name.should == 'Default'
        item.description.should == 'Comment'
        item.valid?.should == true
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

        $api.should_receive(:post_query).with('finances.php?action=addRecord&invoiceid=3&sectionid=2').and_return({"ok"=>true})

        data1 = [
          Osm::Invoice::Item.new(id: 1, invoice: invoice, record_id: 3, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => 'Comment', :budget_name => 'Default'),
        ]
        data2 = [
          Osm::Invoice::Item.new(id: 1, invoice: invoice, record_id: 3, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => 'Comment', :budget_name => 'Default'),
          Osm::Invoice::Item.new(id: 2, invoice: invoice, record_id: 4, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => '', :budget_name => 'Default'),
        ]
        invoice.should_receive(:get_items).with($api, no_read_cache: true).and_return(data1, data2)

        [
          # osm_name, new_value
          ['amount', '1.23'],
          ['comments', 'A description'],
          ['type', 'Expense'],
          ['payto_userid', 'Person to Pay'],
          ['categoryid', 'A budget'],
          ['entrydate', '2003-05-06'],
        ].each do |osm_name, new_value|
          $api.should_receive(:post_query).with('finances.php?action=updateRecord&sectionid=2&dateFormat=generic', post_data: {
            'section_id' => 2,
            'invoiceid' => 3,
            'recordid' => 4,
            'row' => 0,
            'column' => osm_name,
            'value' => new_value,
          }).and_return({osm_name => new_value})
        end

        item.create($api).should == true
        item.id.should == 2
        item.record_id.should == 4
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

        $api.should_receive(:post_query).with('finances.php?action=addRecord&invoiceid=3&sectionid=2').and_return({"ok"=>false})

        data = [
          Osm::Invoice::Item.new(id: 1, invoice: invoice, record_id: 3, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => 'Comment', :budget_name => 'Default'),
        ]
        invoice.should_receive(:get_items).with($api, no_read_cache: true).and_return(data)

        item.create($api).should == false
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
          $api.should_receive(:post_query).with('finances.php?action=updateRecord&sectionid=2&dateFormat=generic', post_data: {
            'section_id' => 2,
            'invoiceid' => 3,
            'recordid' => 4,
            'row' => 0,
            'column' => osm_name,
            'value' => new_value,
          }).and_return({osm_name => new_value})
        end

        item.update($api).should == true
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

        $api.should_receive(:post_query).with('finances.php?action=updateRecord&sectionid=2&dateFormat=generic', post_data: {
          'section_id' => 2,
          'invoiceid' => 3,
          'recordid' => 4,
          'row' => 0,
          'column' => 'comments',
          'value' => 'A new description',
        }).and_return({"comments"=>"A description"})

        item.update($api).should == false
      end

      it "Delete (success)" do
        item = Osm::Invoice::Item.new(id: 1, invoice: Osm::Invoice.new(id: 3, section_id: 2))

        $api.should_receive(:post_query).with('finances.php?action=deleteEntry&sectionid=2', post_data: {
          'id' => 1,
        }).and_return({"ok"=>true})

        item.delete($api).should == true
      end

      it "Delete (failure)" do
        item = Osm::Invoice::Item.new(id: 1, invoice: Osm::Invoice.new(id: 2, section_id: 4),)

        $api.should_receive(:post_query).with('finances.php?action=deleteEntry&sectionid=4', post_data: {
          'id' => 1,
        }).and_return({"ok"=>false})

        item.delete($api).should == false
      end

    end

  end

end
