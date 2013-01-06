# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Section" do

  before :each do
    @attributes = {
      :id => 1,
      :name => 'Name',
      :subscription_level => :silver,
      :subscription_expires => (Date.today + 60).strftime('%Y-%m-%d'),
      :type => :cubs,
      :num_scouts => 10,
      :wizard => false,
      :column_names => {:column_names => 'names'},
      :fields => {:fields => true},
      :intouch_fields => {:intouch_fields => true},
      :mobile_fields => {:mobile_fields => true},
      :flexi_records => [],
      :group_id => 3,
      :group_name => '3rd Somewhere'
    }
  end


  it "Create" do
    section = Osm::Section.new(@attributes)

    section.id.should == 1
    section.name.should == 'Name' 
    section.subscription_level.should == :silver
    section.subscription_expires.should == Date.today + 60
    section.type.should == :cubs
    section.num_scouts.should == 10
    section.column_names.should == {:column_names => 'names'}
    section.fields.should == {:fields => true}
    section.intouch_fields.should == {:intouch_fields => true}
    section.mobile_fields.should == {:mobile_fields => true}
    section.group_id.should == 3
    section.group_name.should == '3rd Somewhere'
    section.flexi_records.should == []
    section.valid?.should be_true
  end


  it "Create has sensible defaults" do
    section = Osm::Section.new

    section.subscription_level.should == :unknown
    section.subscription_expires.should == nil
    section.type.should == :unknown
    section.num_scouts.should == nil
    section.column_names.should == {}
    section.fields.should == {}
    section.intouch_fields.should == {}
    section.mobile_fields.should == {}
    section.flexi_records.should == []
  end


  describe "Using the API" do

    before :each do
      body = [
        {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Flexi Record 1\",\"extraid\":\"111\"}],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
        {"sectionConfig"=>"{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", "groupname"=>"1st Somewhere", "groupid"=>"1", "groupNormalised"=>"1", "sectionid"=>"2", "sectionname"=>"Section 2", "section"=>"cubs", "isDefault"=>"0", "permissions"=>{"badge"=>100, "member"=>100, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}}
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json)
    end

    it "Gets all sections" do
      sections = Osm::Section.get_all(@api)
      sections.map{ |i| i.id }.should == [1, 2]

      section = sections[0]
      section.id.should == 1
      section.name.should == 'Section 1' 
      section.subscription_level.should == :bronze
      section.subscription_expires.should == Date.new(2013, 1, 5)
      section.type.should == :beavers
      section.num_scouts.should == 10
      section.column_names.should == {:column_names => 'names'}
      section.fields.should == {:fields => true}
      section.intouch_fields.should == {:intouch_fields => true}
      section.mobile_fields.should == {:mobile_fields => true}
      section.group_id.should == 3
      section.group_name.should == '3rd Somewhere'
      section.flexi_records.size.should == 1
      section.flexi_records[0].id.should == 111
      section.flexi_records[0].name.should == 'Flexi Record 1'
    end
  
    it "Gets a section" do
      section = Osm::Section.get(@api, 1)
      section.should_not be_nil
      section.id.should == 1
    end

    it "Fetches user's permissions" do
      permissions = Osm::Section.fetch_user_permissions(@api)
      permissions[1].should_not be_nil
      permissions[1].should == {
        :badge => [:read],
        :member => [:read, :write],
        :user => [:read, :write, :administer],
        :register => [:read, :write, :administer],
        :contact => [:read, :write, :administer],
        :programme => [:read, :write, :administer],
        :originator => [],
        :events => [:read, :write, :administer],
        :finance => [:read, :write, :administer],
        :flexi => [:read, :write, :administer],
      }
    end

    it "Gets the section's notepad" do
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getNotepads", :body => {"1" => "Section 1", "2" => "Section 2"}.to_json)
      section = Osm::Section.get(@api, 1)
      section.should_not be_nil
      section.get_notepad(@api).should == 'Section 1'
    end

    it "Fetch badge stock levels" do
      badges_body = {
        'stock' => {
          'sectionid' => '1',
          'badge_1' => '1',
          'badge_2' => '2'
        }
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/challenges.php?action=getInitialBadges&type=core&sectionid=1&section=beavers&termid=2", :body => badges_body.to_json)

      section = Osm::Section.get(@api, 1)
      section.should_not be_nil
      section.get_badge_stock(@api, 2).should == {'badge_1' => 1, 'badge_2' => 2}
    end

  end


  describe "Compare two sections" do

    it "They match" do
      section1 = Osm::Section.new(@attributes)
      section2 = Osm::Section.new(@attributes)

      section1.should == section2
    end

    it "They don't match" do
      section1 = Osm::Section.new(@attributes)
      section2 = Osm::Section.new(@attributes.merge(:id => 2))

      section1.should_not == section2
    end

  end


  it "Sorts by Group Name then section type (age order)" do
    section1 = Osm::Section.new(@attributes.merge(:group_id => 1, :group_name => '1st Somewhere', :type => :beavers))
    section2 = Osm::Section.new(@attributes.merge(:group_id => 2, :group_name => '2nd Somewhere', :type => :beavers))
    section3 = Osm::Section.new(@attributes.merge(:group_id => 2, :group_name => '2nd Somewhere', :type => :cubs))

    [section2, section3, section1].sort.should == [section1, section2, section3]
  end


  describe "Correctly works out the section type" do
    unknown   = Osm::Section.new(:type => :abc)
    beavers   = Osm::Section.new(:type => :beavers)
    cubs      = Osm::Section.new(:type => :cubs)
    scouts    = Osm::Section.new(:type => :scouts)
    explorers = Osm::Section.new(:type => :explorers)
    adults    = Osm::Section.new(:type => :adults)
    waiting   = Osm::Section.new(:type => :waiting)

    {:beavers => beavers, :cubs => cubs, :scouts => scouts, :explorers => explorers, :adults => adults, :waiting => waiting, :unknown => unknown}.each do |section_type, section|
      it "For a #{section_type} section" do
        [:beavers, :cubs, :scouts, :explorers, :adults, :waiting].each do |type|
          section.send("#{type.to_s}?").should == (section_type == type)
        end
      end
    end
  end


  describe "Correctly works out if the section is a youth section" do
    unknown =   Osm::Section.new(:type => :abc)
    beavers =   Osm::Section.new(:type => :beavers)
    cubs =      Osm::Section.new(:type => :cubs)
    scouts =    Osm::Section.new(:type => :scouts)
    explorers = Osm::Section.new(:type => :explorers)
    adults =    Osm::Section.new(:type => :adults)
    waiting =   Osm::Section.new(:type => :waiting)

    [beavers, cubs, scouts, explorers].each do |section|
      it "For a #{section.type} section" do
        section.youth_section?.should be_true
      end
    end
    [adults, waiting, unknown].each do |section|
      it "For a #{section.type} section" do
        section.youth_section?.should be_false
      end
    end
  end

end



describe "Section::FlexiRecord" do

  it "Create" do
    fr = Osm::Section::FlexiRecord.new(:id => 1, :name => 'Name')

    fr.id.should == 1
    fr.name.should == 'Name' 
    fr.valid?.should be_true
  end


  it "Sorts Flexi Records by name" do
    fr1 = Osm::Section::FlexiRecord.new(:id => 3, :name => 'A')
    fr2 = Osm::Section::FlexiRecord.new(:id => 2, :name => 'B')
    fr3 = Osm::Section::FlexiRecord.new(:id => 1, :name => 'C')
    records = [fr2, fr1, fr3]

    records.sort.should == [fr1, fr2, fr3]
  end

end



describe "Online Scout Manager API Strangeness" do

  it "handles a section with no type" do
    body = '[{"sectionConfig":"{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member\'s Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member\'s Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Subs\",\"extraid\":\"529\"}],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}","groupname":"1st Somewhere","groupid":"1","groupNormalised":"1","sectionid":"1","sectionname":"Section 1","section":"cubs","isDefault":"1","permissions":{"badge":100,"member":100,"user":100,"register":100,"contact":100,"programme":100,"originator":1,"events":100,"finance":100,"flexi":100}}]'
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body)

    sections = Osm::Section.get_all(@api)
    sections.size.should == 1
    section = sections[0]
    section.should_not be_nil
    section.type.should == :unknown
  end

  it "handles strange extra records when getting roles" do
    body = '[{"sectionConfig":"{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member\'s Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member\'s Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[[\"1\",{\"name\":\"Subs\",\"extraid\":\"529\"}],[\"2\",{\"name\":\"Subs 2\",\"extraid\":\"530\"}]],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}","groupname":"1st Somewhere","groupid":"1","groupNormalised":"1","sectionid":"1","sectionname":"Section 1","section":"cubs","isDefault":"1","permissions":{"badge":100,"member":100,"user":100,"register":100,"contact":100,"programme":100,"originator":1,"events":100,"finance":100,"flexi":100}}]'
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body)

    sections = Osm::Section.get_all(@api)
    sections.size.should == 1
    sections[0].should_not be_nil
  end

  it "handles a section config where fields is an empty array" do
    body = '[{"sectionConfig":"{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member\'s Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member\'s Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Subs\",\"extraid\":\"529\"}],\"wizard\":\"false\",\"fields\":[],\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}","groupname":"1st Somewhere","groupid":"1","groupNormalised":"1","sectionid":"1","sectionname":"Section 1","section":"cubs","isDefault":"1","permissions":{"badge":100,"member":100,"user":100,"register":100,"contact":100,"programme":100,"originator":1,"events":100,"finance":100,"flexi":100}}]'
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body)

    sections = Osm::Section.get_all(@api)
    sections.size.should == 1
    section = sections[0]
    section.should_not be_nil
    section.fields.should == {}
  end

  it "handles a section's flexi records being a hash" do
    body = [
      {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":{\"1\":{\"name\":\"Flexi Record 1\",\"extraid\":\"1\"},\"2\":{\"name\":\"Flexi Record 2\",\"extraid\":\"2\"}},\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>100, "member"=>100, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
    ]
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json)

    sections = Osm::Section.get_all(@api)
    sections.size.should == 1
    section = sections[0]
    section.should_not be_nil
    section.flexi_records.size.should == 2
    fr = section.flexi_records[0]
    fr.id.should == 1
    fr.name.should == 'Flexi Record 1'
  end

  it "handles an empty array representing no notepads" do
    body = [{"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Flexi Record 1\",\"extraid\":\"111\"}],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}}]
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json)
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getNotepads", :body => '[]')

    section = Osm::Section.get(@api, 1)
    section.should_not be_nil
    section.get_notepad(@api).should == ''
  end

  it "skips a 'discount' section" do
    body = [
      {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>100, "member"=>100, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
      {"sectionConfig"=>"{\"code\":1,\"districts\":[\"Loddon\",\"Kennet\"]}","groupname"=>"Berkshire","groupid"=>"2","groupNormalised"=>"1","sectionid"=>"3","sectionname"=>"County Admin","section"=>"discount","isDefault"=>"0","permissions"=>{"districts"=>["Loddon"]}}
    ]
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json)

    sections = Osm::Section.get_all(@api)
    sections.size.should == 1
    section = sections[0]
    section.should_not be_nil
    section.id.should == 1
  end

  it "handles section config being either a Hash or a JSON encoded Hash" do
    body = [
      {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Flexi Record 1\",\"extraid\":\"111\"}],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
      {"sectionConfig"=>{"subscription_level"=>3,"subscription_expires"=>"2013-01-05","sectionType"=>"cubs","columnNames"=>{"phone1"=>"Home Phone","phone2"=>"Parent 1 Phone","address"=>"Member's Address","phone3"=>"Parent 2 Phone","address2"=>"Address 2","phone4"=>"Alternate Contact Phone","subs"=>"Gender","email1"=>"Parent 1 Email","medical"=>"Medical / Dietary","email2"=>"Parent 2 Email","ethnicity"=>"Gift Aid","email3"=>"Member's Email","religion"=>"Religion","email4"=>"Email 4","school"=>"School"},"numscouts"=>10,"hasUsedBadgeRecords"=>true,"hasProgramme"=>true,"extraRecords"=>[],"wizard"=>"false","fields"=>{"email1"=>true,"email2"=>true,"email3"=>true,"email4"=>false,"address"=>true,"address2"=>false,"phone1"=>true,"phone2"=>true,"phone3"=>true,"phone4"=>true,"school"=>false,"religion"=>true,"ethnicity"=>true,"medical"=>true,"patrol"=>true,"subs"=>true,"saved"=>true},"intouch"=>{"address"=>true,"address2"=>false,"email1"=>false,"email2"=>false,"email3"=>false,"email4"=>false,"phone1"=>true,"phone2"=>true,"phone3"=>true,"phone4"=>true,"medical"=>false},"mobFields"=>{"email1"=>false,"email2"=>false,"email3"=>false,"email4"=>false,"address"=>true,"address2"=>false,"phone1"=>true,"phone2"=>true,"phone3"=>true,"phone4"=>true,"school"=>false,"religion"=>false,"ethnicity"=>true,"medical"=>true,"patrol"=>true,"subs"=>false}}, "groupname"=>"1st Somewhere", "groupid"=>"1", "groupNormalised"=>"1", "sectionid"=>"2", "sectionname"=>"Section 2", "section"=>"cubs", "isDefault"=>"0", "permissions"=>{"badge"=>100, "member"=>100, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}}
    ]
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json)

    sections = Osm::Section.get_all(@api)
    sections.size.should == 2
    sections[0].should_not be_nil
    sections[1].should_not be_nil
  end

end
