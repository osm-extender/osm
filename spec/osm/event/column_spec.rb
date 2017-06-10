describe Osm::Event::Column do

  describe 'Using to OSM API' do

    it 'Update column (succeded)' do
      post_data = {
        'columnId' => 'f_1',
        'columnName' => 'New name',
        'pL' => 'New label',
        'pR' => 1
      }
      body = {
        'eventid' => '2',
        'config' => '[{"id":"f_1","name":"New name","pL":"New label","pR":"1"}]'
      }
      expect($api).to receive(:post_query).with('events.php?action=renameColumn&sectionid=1&eventid=2', post_data: post_data).and_return(body)

      event = Osm::Event.new(id: 2, section_id: 1)
      event.columns = [Osm::Event::Column.new(id: 'f_1', event: event)]
      column = event.columns[0]
      column.name = 'New name'
      column.label = 'New label'
      column.parent_required = true

      expect(column.update($api)).to eq(true)

      expect(column.name).to eq('New name')
      expect(column.label).to eq('New label')
      expect(event.columns[0].name).to eq('New name')
      expect(event.columns[0].label).to eq('New label')
    end

    it 'Update column (failed)' do
      expect($api).to receive(:post_query).and_return({ 'config' => '[]' })

      event = Osm::Event.new(id: 2, section_id: 1)
      column = Osm::Event::Column.new(id: 'f_1', event: event)
      event.columns = [column]
      expect(column.update($api)).to eq(false)
    end

    it 'Delete column (succeded)' do
      post_data = {
        'columnId' => 'f_1'
      }

      expect($api).to receive(:post_query).with('events.php?action=deleteColumn&sectionid=1&eventid=2', post_data: post_data).and_return({ 'eventid' => '2', 'config' => '[]' })

      event = Osm::Event.new(id: 2, section_id: 1)
      column = Osm::Event::Column.new(id: 'f_1', event: event)
      event.columns = [column]

      expect(column.delete($api)).to eq(true)
      expect(event.columns).to eq([])
    end

    it 'Delete column (failed)' do
      expect($api).to receive(:post_query).and_return({ 'config' => '[{"id":"f_1"}]' })

      event = Osm::Event.new(id: 2, section_id: 1)
      column = Osm::Event::Column.new(id: 'f_1', event: event)
      event.columns = [column]
      expect(column.delete($api)).to eq(false)
    end

  end # describe using to OSM API

end
