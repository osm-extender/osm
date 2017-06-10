describe Osm::Sms do

  describe 'Send an SMS' do

    it 'One person' do
      allow(Osm::Sms).to receive(:number_selected) { 2 }
      allow(Osm::Sms).to receive(:remaining_credits) { 3 }

      expect($api).to receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
        'msg' => 'Test message.',
        'scouts' => '4',
        'source' => '441234567890',
        'type' => ''
      }){ { 'result' => true, 'msg' => "Message sent - you have <b>131<\/b> credits left.", 'config' => {} } }

      result = Osm::Sms.send_sms(
        api:     $api,
        section: 1,
        members: 4,
        source_address: '441234567890',
        message: 'Test message.'
      )
      expect(result).to eq(true)
    end

    it 'Several people' do
      allow(Osm::Sms).to receive(:number_selected) { 3 }
      allow(Osm::Sms).to receive(:remaining_credits) { 3 }

      expect($api).to receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
        'msg' => 'This is a test message.',
        'scouts' => '2,3',
        'source' => '441234567890',
        'type' => ''
      }){ { 'result' => true, 'msg' => "Message sent - you have <b>95<\/b> credits left.", 'config' => {} } }

      result = Osm::Sms.send_sms(
        api:     $api,
        section: 1,
        members: [2, 3],
        source_address: '441234567890',
        message: 'This is a test message.'
      )
      expect(result).to eq(true)
    end

    it 'Failed' do
      allow(Osm::Sms).to receive(:number_selected) { 3 }
      allow(Osm::Sms).to receive(:remaining_credits) { 3 }

      expect($api).to receive(:post_query).with('ext/members/sms/?action=sendText&sectionid=1', post_data: {
        'msg' => 'Test message.',
        'scouts' => '4',
        'source' => '441234567890',
        'type' => ''
      }){ { 'result' => false,'config' => {} } }

      result = Osm::Sms.send_sms(
        api:     $api,
        section: 1,
        members: [4],
        source_address: '441234567890',
        message: 'Test message.'
      )
      expect(result).to eq(false)
    end

    it 'Raises error if not enough credits' do
      allow(Osm::Sms).to receive(:number_selected) { 3 }
      allow(Osm::Sms).to receive(:remaining_credits) { 2 }
      expect($api).not_to receive(:post_query)

      expect {
        Osm::Sms.send_sms(api: $api, section: 1, members: [2, 3], source_address: '441234567890', message: 'Test message.')
      }.to raise_error(Osm::Error, 'You do not have enough credits to send that message.')
    end

  end

  it 'Gets remaining credits' do
    expect($api).to receive(:post_query).with('ext/members/sms/?action=getNumbers&sectionid=4&type=', post_data: {
      'scouts' => '0'
    }){ { 'members' => 0, 'numbers' => 0, 'sms_remaining' => 5 } }

    expect(Osm::Sms.remaining_credits(api: $api, section: 4)).to eq(5)
  end

  it 'Gets selected numbers' do
    expect($api).to receive(:post_query).with('ext/members/sms/?action=getNumbers&sectionid=4&type=', post_data: {
      'scouts' => '12,56'
    }){ { 'members' => 2, 'numbers' => 3, 'sms_remaining' => 5 } }

    expect(Osm::Sms.number_selected(api: $api, section: 4, members: [12, 56])).to eq(3)
  end

end
