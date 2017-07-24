describe OSM::MyScout::Template do

  describe 'Get' do

    it 'Success' do
      expect($api).to receive(:post_query).with('ext/settings/parents/?action=getTemplate&key=email-first&section_id=1').and_return('status' => true, 'error' => nil, 'data' => 'TEMPLATE GOES HERE', 'meta' => [])
      expect(OSM::MyScout::Template.get_template(api: $api, section: 1, key: 'email-first')).to eq('TEMPLATE GOES HERE')
    end

    it 'Failed' do
      expect($api).to receive(:post_query).with('ext/settings/parents/?action=getTemplate&key=email-first&section_id=1').and_return('status' => false, 'error' => nil, 'data' => '', 'meta' => [])
      expect(OSM::MyScout::Template.get_template(api: $api, section: 1, key: 'email-first')).to be_nil
    end

  end # describe get


  describe 'Update' do

    it 'Success' do
      template = 'CONTENT WHICH CONTAINS [DIRECT_LINK].'
      expect($api).to receive(:post_query).with('ext/settings/parents/?action=updateTemplate', post_data: { 'section_id' => 1, 'key' => 'email-invitation', 'value' => template }).and_return('status' => true, 'error' => nil, 'data' => true, 'meta' => [])
      expect(OSM::MyScout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: template)).to be true
    end

    it 'Failed' do
      template = 'CONTENT WHICH CONTAINS [DIRECT_LINK].'
      expect($api).to receive(:post_query).with('ext/settings/parents/?action=updateTemplate', post_data: { 'section_id' => 1, 'key' => 'email-invitation', 'value' => template }).and_return('status' => false, 'error' => nil, 'data' => false, 'meta' => [])
      expect(OSM::MyScout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: template)).to be false
    end

    it 'Missing a required tag' do
      expect($api).not_to receive(:post_query)
      expect { OSM::MyScout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: 'CONTENT') }.to raise_error ArgumentError, 'Required tag [DIRECT_LINK] not found in template content.'
    end

  end # desxribe update


  describe 'Restore' do

    it 'Success' do
      expect($api).to receive(:post_query).with('ext/settings/parents/?action=restoreTemplate', post_data: { 'section_id' => 1, 'key' => 'email-first' }).and_return('status' => true, 'error' => nil, 'data' => 'TEMPLATE GOES HERE', 'meta' => [])
      expect(OSM::MyScout::Template.restore_template(api: $api, section: 1, key: 'email-first')).to eq('TEMPLATE GOES HERE')
    end

    it 'Failed' do
      expect($api).to receive(:post_query).with('ext/settings/parents/?action=restoreTemplate', post_data: { 'section_id' => 1, 'key' => 'email-first' }).and_return('status' => false, 'error' => nil, 'data' => 'TEMPLATE GOES HERE', 'meta' => [])
      expect(OSM::MyScout::Template.restore_template(api: $api, section: 1, key: 'email-first')).to be_nil
    end

  end # describe restore

end
