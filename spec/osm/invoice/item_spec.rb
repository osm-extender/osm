describe Osm::Invoice::Item do

  it 'Create' do
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

  it 'Sorts by Invoice then Date' do
    i1 = Osm::Invoice.new(section_id: 1, name: 'a', date: Date.new(2000, 1, 2))
    i2 = Osm::Invoice.new(section_id: 2, name: 'a', date: Date.new(2000, 1, 2))
    ii1 = Osm::Invoice::Item.new(invoice: i1, date: Date.new(2000, 1, 1))
    ii2 = Osm::Invoice::Item.new(invoice: i2, date: Date.new(2000, 1, 1))
    ii3 = Osm::Invoice::Item.new(invoice: i2, date: Date.new(2000, 1, 2))

    data = [ii2, ii3, ii1]
    expect(data.sort).to eq([ii1, ii2, ii3])
  end

  it 'Calculates value for easy summing' do
    expect(Osm::Invoice::Item.new(type: :income, amount: '1.00').value).to eq(1.00)
    expect(Osm::Invoice::Item.new(type: :expense, amount: '2.00').value).to eq(-2.00)
  end


  describe 'Using the OSM API' do

    it 'Get for invoice' do
      data = {'identifier' => 'id','items' => [
        {'id' => '1','invoiceid' => '2','recordid' => '3','sectionid' => '4','entrydate' => '2012-01-02','amount' => '1.23','type' => 'Expense','payto_userid' => 'John Smith','comments' => 'Comment','categoryid' => 'Default','firstname' => 'John Smith'}
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

    describe 'Create' do
 
      it 'Success' do
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
        expect($api).to receive(:post_query).with('finances.php?action=addRecord&invoiceid=3&sectionid=2').and_return({'ok'=>true})

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

      it 'Failure to create' do
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
        expect($api).to receive(:post_query).with('finances.php?action=addRecord&invoiceid=3&sectionid=2').and_return({'ok'=>false})

        data = [
          Osm::Invoice::Item.new(id: 1, invoice: invoice, record_id: 3, date: Date.new(2012, 1, 2), amount: '1.23', :type => :expense, :payto => 'John Smith', :description => 'Comment', :budget_name => 'Default'),
        ]
        expect(invoice).to receive(:get_items).with($api, no_read_cache: true).and_return(data)
        expect(item.create($api)).to eq(false)
      end

    end # describe create


    describe 'Update' do

      it 'Success' do
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

      it 'Failure' do
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
        expect($api).to receive(:post_query).with('finances.php?action=updateRecord&sectionid=2&dateFormat=generic', post_data: {
          'section_id' => 2,
          'invoiceid' => 3,
          'recordid' => 4,
          'row' => 0,
          'column' => 'comments',
          'value' => 'A new description',
        }).and_return({'comments'=>'A description'})

        item.description = 'A new description'
        expect(item.update($api)).to eq(false)
      end

    end # describe update


    describe 'Delete' do

      it 'Success' do
        item = Osm::Invoice::Item.new(id: 1, invoice: Osm::Invoice.new(id: 3, section_id: 2))
        expect($api).to receive(:post_query).with('finances.php?action=deleteEntry&sectionid=2', post_data: {
          'id' => 1,
        }).and_return({'ok'=>true})

        expect(item.delete($api)).to eq(true)
      end

      it 'Failure' do
        item = Osm::Invoice::Item.new(id: 1, invoice: Osm::Invoice.new(id: 2, section_id: 4),)
        expect($api).to receive(:post_query).with('finances.php?action=deleteEntry&sectionid=4', post_data: {
          'id' => 1,
        }).and_return({'ok'=>false})

        expect(item.delete($api)).to eq(false)
      end

    end # describe delete

  end # describe using the OSM API

end
