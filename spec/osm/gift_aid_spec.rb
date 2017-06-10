describe Osm::GiftAid do

  describe 'Using the API' do

    it 'Fetch the donations for a section' do
      data = [
    	  { 'rows' => [
          { 'name' => 'First name','field' => 'firstname','width' => '100px','formatter' => 'boldFormatter' },
          { 'name' => 'Last name','field' => 'lastname','width' => '100px','formatter' => 'boldFormatter' },
          { 'name' => "Tax payer's name",'field' => 'parentname','width' => '150px','editable' => true,'formatter' => 'boldFormatter' },
          { 'name' => 'Total','field' => 'total','width' => '60px','formatter' => 'boldFormatter' }
	      ],'noscroll' => true },
	      { 'rows' => [
          { 'name' => '2000-01-02', 'field' => '2000-01-02', 'width' => '110px', 'editable' => true, 'formatter' => 'boldFormatter' }
      	] }
      ]
      expect($api).to receive(:post_query).with('giftaid.php?action=getStructure&sectionid=1&termid=2').and_return(data)

      donations = Osm::GiftAid.get_donations(api: $api, section: 1, term: 2)
      expect(donations).to eq([Osm::GiftAid::Donation.new(donation_date: Date.new(2000, 1, 2))])
    end

    it 'Fetch the data for a section' do
      data = {
      	'identifier' => 'scoutid',
	      'label' => 'name',
	      'items' => [
	        { '2000-01-02' => '1.23', 'total' => 2.34, 'scoutid' => '2', 'firstname' => 'First', 'lastname' => 'Last', 'patrolid' => '3', 'parentname' => 'Tax' },
	        { '2000-01-02' => 1.23,'firstname' => 'TOTAL','lastname' => '','scoutid' => -1,'patrolid' => -1,'parentname' => '','total' => 1.23 }
	      ]
      }
      expect($api).to receive(:post_query).with('giftaid.php?action=getGrid&sectionid=1&termid=2').and_return(data)

      data = Osm::GiftAid.get_data(api: $api, section: 1, term: 2)
      expect(data.is_a?(Array)).to eq(true)
      expect(data.size).to eq(1)
      data = data[0]
      expect(data.donations).to eq(        Date.new(2000, 1, 2) => '1.23')
      expect(data.first_name).to eq('First')
      expect(data.last_name).to eq('Last')
      expect(data.tax_payer_name).to eq('Tax')
      expect(data.grouping_id).to eq(3)
      expect(data.member_id).to eq(2)
      expect(data.total).to eq('2.34')
      expect(data.section_id).to eq(1)
      expect(data.valid?).to eq(true)
    end

    it 'Update donation' do
      post_data = {
        'scouts' => '["3", "4"]',
        'donatedate'=> '2000-01-02',
        'amount' => '1.23',
        'notes' => 'Note',
        'sectionid' => 1,
      }
      expect($api).to receive(:post_query).with('giftaid.php?action=update&sectionid=1&termid=2', post_data: post_data).and_return([])

      expect(Osm::GiftAid.update_donation(
        api: $api,
        section: 1,
        term: 2,
        date: Date.new(2000, 1, 2),
        members: [3, 4],
        amount: '1.23',
        note: 'Note',
      )).to eq(true)
    end

  end # Describe using the API

end
