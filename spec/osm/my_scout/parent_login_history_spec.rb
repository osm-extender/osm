describe Osm::MyScout::ParentLoginHistory do

  it 'Get from OSM' do
    data = { 'items' => [
      { 'scoutid' => '2', 'firstname' => 'John', 'lastname' => 'Smith', 'numlogins' => 271, 'lastlogin' => '16/04/2016 17:49' },
      { 'scoutid' => '3', 'firstname' => 'Jane', 'lastname' => 'Jones', 'numlogins' => 1, 'lastlogin' => '10/11/2015 14:21' }
    ] }
    expect($api).to receive(:post_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1').and_return(data)

    histories = Osm::MyScout::ParentLoginHistory.get_for_section(api: $api, section: 1)
    expect(histories.size).to eq(2)
    expect(histories[0].member_id).to eq(2)
    expect(histories[0].first_name).to eq('John')
    expect(histories[0].last_name).to eq('Smith')
    expect(histories[0].logins).to eq(271)
    expect(histories[0].last_login).to eq(Time.new(2016, 4, 16, 17, 49))
    expect(histories[1].member_id).to eq(3)
    expect(histories[1].first_name).to eq('Jane')
    expect(histories[1].last_name).to eq('Jones')
    expect(histories[1].logins).to eq(1)
    expect(histories[1].last_login).to eq(Time.new(2015, 11, 10, 14, 21))
  end

  it 'Handles a last_login of "Invitation not sent"' do
    data = { 'items' => [
      { 'scoutid' => '2', 'firstname' => 'John', 'lastname' => 'Smith', 'numlogins' => 271, 'lastlogin' => 'Invitation not sent' }
    ] }

    expect($api).to receive(:post_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1').and_return(data)

    history = Osm::MyScout::ParentLoginHistory.get_for_section(api: $api, section: 1)[0]
    expect(history.last_login).to be_nil
  end

  it 'Handles a nil last_login' do
    data = { 'items' => [
      { 'scoutid' => '2', 'firstname' => 'John', 'lastname' => 'Smith', 'numlogins' => 271, 'lastlogin' => nil }
    ] }
    expect($api).to receive(:post_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1').and_return(data)

    history = Osm::MyScout::ParentLoginHistory.get_for_section(api: $api, section: 1)[0]
    expect(history.last_login).to be_nil
  end

end
