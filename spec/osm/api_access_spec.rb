describe Osm::ApiAccess do

  it "Create" do
    data = {
      id: 1,
      name: 'Name',
      permissions: {permission: [:read]},
    }
    api_access = Osm::ApiAccess.new(data)

    expect(api_access.id).to eq(1)
    expect(api_access.name).to eq('Name')
    expect(api_access.permissions).to eq({permission: [:read]})
    expect(api_access.valid?).to eq(true)
  end

  it "Sorts by id" do
    a1 = Osm::ApiAccess.new(id: 1)
    a2 = Osm::ApiAccess.new(id: 2)

    data = [a2, a1]
    expect(data.sort).to eq([a1, a2])
  end


  describe "Using the API" do

    before :each do
      body = {
        'apis' => [
          {
            'apiid' => '1',
            'name' => 'API Name',
            'permissions' => { 'read' => '10', 'readwrite' => '20', 'administer' => '100' }
          }, {
            'apiid' => '2',
            'name' => 'API 2 Name',
            'permissions' => { 'read' => '10', 'readwrite' => '20' }
          }
        ]
      }
      expect($api).to receive(:post_query).with('ext/settings/access/?action=getAPIAccess&sectionid=1').and_return(body)
    end

    describe "Get All" do
      it "From OSM" do
        api_accesses = Osm::ApiAccess.get_all(api: $api, section: 1)
  
        expect(api_accesses.size).to eq(2)
        api_access = api_accesses[0]
        expect(api_access.id).to eq(1)
        expect(api_access.name).to eq('API Name')
        expect(api_access.permissions).to eq({read: [:read], readwrite: [:read, :write], administer: [:read, :write, :administer]})
      end

      it "From cache" do
        api_accesses = Osm::ApiAccess.get_all(api: $api, section: 1)
        expect($api).not_to receive(:post_query)
        expect(Osm::ApiAccess.get_all(api: $api, section: 1)).to eq(api_accesses)
      end
    end

    it "Get One" do
      api_access = Osm::ApiAccess.get(api: $api, section: 1, for_api: 2)
      expect(api_access.id).to eq(2)
    end

    it "Get Ours" do
      api_access = Osm::ApiAccess.get_ours(api: $api, section: 1)
      expect(api_access.id).to eq(1)
    end

  end

end
