describe Osm::GiftAid::Data do

  it 'Create' do
    d = Osm::GiftAid::Data.new(
      member_id: 1,
      first_name: 'A',
      last_name: 'B',
      tax_payer_name: 'C',
      tax_payer_address: 'D',
      tax_payer_postcode: 'E',
      section_id: 2,
      grouping_id: 3,
      total: '2.34',
      donations: {
        Date.new(2012, 1, 2) => '1.23',
      }
    )

    expect(d.member_id).to eq(1)
    expect(d.section_id).to eq(2)
    expect(d.grouping_id).to eq(3)
    expect(d.first_name).to eq('A')
    expect(d.last_name).to eq('B')
    expect(d.tax_payer_name).to eq('C')
    expect(d.tax_payer_address).to eq('D')
    expect(d.tax_payer_postcode).to eq('E')
    expect(d.total).to eq('2.34')
    expect(d.donations).to eq(      Date.new(2012, 1, 2) => '1.23')
    expect(d.valid?).to eq(true)
  end

  it 'Sorts by section_id, grouping_id, last_name then first_name' do
    d1 = Osm::GiftAid::Data.new(section_id: 1, grouping_id: 1, last_name: 'a', first_name: 'a')
    d2 = Osm::GiftAid::Data.new(section_id: 2, grouping_id: 1, last_name: 'a', first_name: 'a')
    d3 = Osm::GiftAid::Data.new(section_id: 2, grouping_id: 2, last_name: 'a', first_name: 'a')
    d4 = Osm::GiftAid::Data.new(section_id: 2, grouping_id: 2, last_name: 'b', first_name: 'a')
    d5 = Osm::GiftAid::Data.new(section_id: 2, grouping_id: 2, last_name: 'b', first_name: 'b')

    data = [d4, d3, d5, d2, d1]
    expect(data.sort).to eq([d1, d2, d3, d4, d5])
  end


  describe 'Using the OSM API' do

    describe 'Update' do

      before :each do
        @data = Osm::GiftAid::Data.new(
          member_id: 1,
          first_name: 'A',
          last_name: 'B',
          tax_payer_name: 'C',
          tax_payer_address: 'D',
          tax_payer_postcode: 'E',
          section_id: 2,
          grouping_id: 3,
          total: '2.34',
          donations: {
            Date.new(2012, 1, 2) => '1.23',
            Date.new(2012, 1, 3) => '2.34',
          }
        )
        allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 4) }
      end

      it 'Tax payer' do
        post_data = {
          'scoutid' => 1,
          'termid' => 4,
          'sectionid' => 2,
          'row' => 0,
        }
        body_data = {
          'items' => [
            { 'parentname' => 'n', 'address' => 'a', 'postcode' => 'pc', 'scoutid' => '1' },
            { 'firstname' => 'TOTAL','lastname' => '','scoutid' => -1,'patrolid' => -1,'parentname' => '','total' => 0 }
          ]
        }
        expect($api).to receive(:post_query).with('giftaid.php?action=updateScout', post_data: post_data.merge('column' => 'parentname', 'value' => 'n')).and_return(body_data)
        expect($api).to receive(:post_query).with('giftaid.php?action=updateScout', post_data: post_data.merge('column' => 'address', 'value' => 'a')).and_return(body_data)
        expect($api).to receive(:post_query).with('giftaid.php?action=updateScout', post_data: post_data.merge('column' => 'postcode', 'value' => 'pc')).and_return(body_data)

        @data.tax_payer_name = 'n'
        @data.tax_payer_address = 'a'
        @data.tax_payer_postcode = 'pc'
        expect(@data.update($api)).to eq(true)
      end

      it 'A donation' do
        post_data = {
          'scoutid' => 1,
          'termid' => 4,
          'column' => '2012-01-03',
          'value' => '3.45',
          'sectionid' => 2,
          'row' => 0,
        }
        body_data = {
          'items' => [
            { '2012-01-03' => '3.45','scoutid' => '1' },
            { 'firstname' => 'TOTAL','lastname' => '','scoutid' => -1,'patrolid' => -1,'parentname' => '','total' => 0 }
          ]
        }
        url = 'https://www.onlinescoutmanager.co.uk/'
        expect($api).to receive(:post_query).with('giftaid.php?action=updateScout', post_data: post_data).and_return(body_data)

        @data.donations[Date.new(2012, 1, 3)] = '3.45'
        expect(@data.update($api)).to eq(true)
      end

    end # Describe update data

  end # describe using the OSM API

end
