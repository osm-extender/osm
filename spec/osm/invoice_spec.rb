describe Osm::Invoice do

  it 'Create Invoice' do
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

  it 'Sorts Invoice by Section ID, Name then Date' do
    i1 = Osm::Invoice.new(section_id: 1, name: 'a', date: Date.new(2000, 1, 2))
    i2 = Osm::Invoice.new(section_id: 2, name: 'a', date: Date.new(2000, 1, 2))
    i3 = Osm::Invoice.new(section_id: 2, name: 'b', date: Date.new(2000, 1, 2))
    i4 = Osm::Invoice.new(section_id: 2, name: 'b', date: Date.new(2000, 1, 3))

    data = [i2, i4, i1, i3]
    expect(data.sort).to eq([i1, i2, i3, i4])
  end


  describe 'Using the API' do

    describe 'Invoice' do

      describe 'Get for section' do
        before :all do
          @invoices_body = {
            'identifier' => 'invoiceid',
            'label' => 'name',
            'items' => [
              { 'invoiceid' => '1', 'name' => 'Invoice 1' },
              { 'invoiceid' => '2', 'name' => 'Invoice 2' },
            ]
          }

          @invoice1_body = {
            'invoice' => {
              'invoiceid' => '1',
              'sectionid' => '3',
              'name' => 'Invoice 1',
              'extra' => 'Some more details',
              'entrydate' => '2010-01-01',
              'archived' => '0',
              'finalised' => '0'
            },
            'people' => [
              'Person 1',
              'Person 2',
              ''
            ],
            'categories' => [
              'Default',
              'A Budget'
            ]
          }
          @invoice2_body = {
            'invoice' => {
              'invoiceid' => '2',
              'sectionid' => '3',
              'name' => 'Invoice 2',
              'extra' => '',
              'entrydate' => '2010-02-02',
              'archived' => '1',
              'finalised' => '1'
            },
            'people' => [
              'Person 1',
              'Person 2',
              ''
            ],
            'categories' => [
              'Default',
              'A Budget'
            ]
          }
        end

        it 'From API' do
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

        it 'Honours archived option' do
          expect($api).to receive(:post_query).with('finances.php?action=getInvoices&sectionid=3&showArchived=true').and_return(@invoices_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(@invoice1_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=2').and_return(@invoice2_body)

          invoices = Osm::Invoice.get_for_section(api: $api, section: 3, include_archived: true)
          expect(invoices.size).to eq(2)
        end

        it 'From Cache' do
          expect($api).to receive(:post_query).with('finances.php?action=getInvoices&sectionid=3&showArchived=true').and_return(@invoices_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(@invoice1_body)
          expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=2').and_return(@invoice2_body)

          invoices = Osm::Invoice.get_for_section(api: $api, section: 3)
          expect($api).not_to receive(:post_query)
          expect(Osm::Invoice.get_for_section(api: $api, section: 3)).to eq(invoices)
        end

      end

      it 'Get' do
        invoices_body = {
          'identifier' => 'invoiceid',
          'label' => 'name',
          'items' => [
            { 'invoiceid' => '1', 'name' => 'Invoice 1' },
          ]
        }

        invoice1_body = {
          'invoice' => {
            'invoiceid' => '1',
            'sectionid' => '3',
            'name' => 'Invoice 1',
            'extra' => 'Some more details',
            'entrydate' => '2010-01-01',
            'archived' => '0',
            'finalised' => '0'
          },
          'people' => [
            'Person 1',
            'Person 2',
            ''
          ],
          'categories' => [
            'Default',
            'A Budget'
          ]
        }
        expect($api).to receive(:post_query).with('finances.php?action=getInvoice&sectionid=3&invoiceid=1').and_return(invoice1_body)

        invoice = Osm::Invoice.get(api: $api, section: 3, id: 1)
        expect(invoice).not_to be_nil
        expect(invoice.id).to eq(1)
      end

      it 'Create (success)' do
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
        }).and_return('id'=>2)

        expect(invoice.create($api)).to eq(true)
        expect(invoice.id).to eq(2)
      end

      it 'Create (failure)' do
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
        }).and_return('message'=>'Something went wrong')

        expect(invoice.create($api)).to eq(false)
        expect(invoice.id).to be_nil
      end

      it 'Update (success)' do
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
        }).and_return('ok'=>true)

        expect(invoice.update($api)).to eq(true)
      end

      it 'Update (failure)' do
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
        }).and_return('ok'=>false)

        expect(invoice.update($api)).to eq(false)
      end

      it 'Delete (success)' do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
        }).and_return('ok'=>true)

        expect(invoice.delete($api)).to eq(true)
      end

      it 'Delete (failure)' do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
        }).and_return('ok'=>false)

        expect(invoice.delete($api)).to eq(false)
      end

      it 'Finalise invoice (success)' do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=finaliseInvoice&sectionid=2&invoiceid=1').and_return('ok'=>true)

        expect(invoice.finalise($api)).to eq(true)
        expect(invoice.finalised).to eq(true)
      end

      it 'Finalise invoice (failure)' do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=finaliseInvoice&sectionid=2&invoiceid=1').and_return('ok'=>false)

        expect(invoice.finalise($api)).to eq(false)
        expect(invoice.finalised).to eq(false)
      end

      it 'Finalise invoice (already finalised)' do
        invoice = Osm::Invoice.new(id: 1, section_id: 2, finalised: true)

        expect($api).not_to receive(:post_query)

        expect(invoice.finalise($api)).to eq(false)
        expect(invoice.finalised).to eq(true)
      end

      it 'Archive invoice (success)' do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'archived' => 1,
        }).and_return('ok'=>true)

        expect(invoice.archive($api)).to eq(true)
        expect(invoice.archived).to eq(true)
      end

      it 'Archive invoice (failure)' do
        invoice = Osm::Invoice.new(id: 1, section_id: 2)

        expect($api).to receive(:post_query).with('finances.php?action=deleteInvoice&sectionid=2', post_data: {
          'invoiceid' => 1,
          'archived' => 1,
        }).and_return('ok'=>false)

        expect(invoice.archive($api)).to eq(false)
        expect(invoice.archived).to eq(false)
      end

      it 'Archive invoice (already archived)' do
        invoice = Osm::Invoice.new(id: 1, section_id: 2, archived: true)

        expect($api).not_to receive(:post_query)

        expect(invoice.archive($api)).to eq(false)
        expect(invoice.archived).to eq(true)
      end

    end

  end # describe using the OSM API

end
