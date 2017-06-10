describe Osm::Budget do

  it 'Create Budget' do
    b = Osm::Budget.new(
      id: 1,
      section_id: 2,
      name: 'Name'
    )

    expect(b.id).to eq(1)
    expect(b.section_id).to eq(2)
    expect(b.name).to eq('Name')
    expect(b.valid?).to eq(true)
  end

  it 'Sorts Budget by section ID then name' do
    b1 = Osm::Budget.new(section_id: 1, name: 'a')
    b2 = Osm::Budget.new(section_id: 2, name: 'a')
    b3 = Osm::Budget.new(section_id: 2, name: 'b')

    data = [b2, b3, b1]
    expect(data.sort).to eq([b1, b2, b3])
  end


  describe 'Using the API' do

    it 'Get budgets for section' do
      data = {
        'identifier' => 'categoryid',
        'items' => [
          {
            'categoryid' => '2',
            'sectionid' => '3',
            'name' => 'Name',
            'archived' => '1'
          }
        ]
      }
      expect($api).to receive(:post_query).with('finances.php?action=getCategories&sectionid=3').and_return(data)

      budgets = Osm::Budget.get_for_section(api: $api, section: 3)
      expect(budgets).to eq([Osm::Budget.new(id: 2, section_id: 3, name: 'Name')])
    end

    it 'Create budget (success)' do
      budget = Osm::Budget.new(
        section_id: 2,
        name: 'Budget Name'
      )

      expect(Osm::Budget).to receive(:get_for_section).with(api: $api, section: 2, no_read_cache: true).and_return([Osm::Budget.new(id: 3, section_id: 2, name: 'Existing budget'), Osm::Budget.new(id: 4, section_id: 2, :name => '** Unnamed **')])
      expect($api).to receive(:post_query).with('finances.php?action=addCategory&sectionid=2').and_return('ok' => true)
      expect($api).to receive(:post_query).with('finances.php?action=updateCategory&sectionid=2', post_data: {
        'categoryid' => 4,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0
      }).and_return('ok' => true)

      expect(budget.create($api)).to eq(true)
      expect(budget.id).to eq(4)
    end

    it 'Create budget (failure (not created))' do
      budget = Osm::Budget.new(
        section_id: 2,
        name: 'Budget Name'
      )
    
      expect($api).to receive(:post_query).with('finances.php?action=addCategory&sectionid=2').and_return('ok' => true)
      expect(Osm::Budget).to receive(:get_for_section).with(api: $api, section: 2, no_read_cache: true).and_return([Osm::Budget.new(id: 3, section_id: 2, name: 'Existing budget')])

      expect(budget.create($api)).to eq(false)
    end
    
    it 'Create budget (failure (not updated))' do
      budget = Osm::Budget.new(
        section_id: 2,
        name: 'Budget Name'
      )
    
      expect(Osm::Budget).to receive(:get_for_section).with(api: $api, section: 2, no_read_cache: true).and_return([Osm::Budget.new(id: 3, section_id: 2, name: '** Unnamed **')])
      expect($api).to receive(:post_query).with('finances.php?action=addCategory&sectionid=2').and_return('ok' => true)
      expect($api).to receive(:post_query).with('finances.php?action=updateCategory&sectionid=2', post_data: {
        'categoryid' => 3,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0
      }).and_return('ok' => false)

      expect(budget.create($api)).to eq(false)
    end
    
    it 'Update budget (success)' do
      budget = Osm::Budget.new(
        id: 1,
        section_id: 2,
        name: 'Budget Name'
      )

      expect($api).to receive(:post_query).with('finances.php?action=updateCategory&sectionid=2', post_data: {
        'categoryid' => 1,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0
      }).and_return('ok' => true)
    
      expect(budget.update($api)).to eq(true)
    end
    
    it 'Update budget (failure)' do
      budget = Osm::Budget.new(
        id: 1,
        section_id: 2,
        name: 'Budget Name'
      )

      expect($api).to receive(:post_query).with('finances.php?action=updateCategory&sectionid=2', post_data: {
        'categoryid' => 1,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0
      }).and_return('ok' => false)
    
      expect(budget.update($api)).to eq(false)
    end
    
    it 'Delete budget (success)' do
      budget = Osm::Budget.new(
        id: 1,
        section_id: 2,
        name: 'Budget Name'
      )

      expect($api).to receive(:post_query).with('finances.php?action=deleteCategory&sectionid=2', post_data: { 'categoryid' => 1 }).and_return('ok' => true)

      expect(budget.delete($api)).to eq(true)
    end
    
    it 'Delete budget (failure)' do
      budget = Osm::Budget.new(
        id: 1,
        section_id: 2,
        name: 'Budget Name'
      )

      expect($api).to receive(:post_query).with('finances.php?action=deleteCategory&sectionid=2', post_data: { 'categoryid' => 1 }).and_return('ok' => false)
    
      expect(budget.delete($api)).to eq(false)
    end
    
  end


end
