# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Section" do

  before :each do
    @attributes = {
      :id => 1,
      :name => 'Name',
      :subscription_level => 2,
      :subscription_expires => (Date.today + 60).strftime('%Y-%m-%d'),
      :type => :cubs,
      :wizard => false,
      :flexi_records => [],
      :group_id => 3,
      :group_name => '3rd Somewhere',
      :gocardless => true,
      :myscout_events_expires => (Date.today + 61).strftime('%Y-%m-%d'),
      :myscout_badges_expires => (Date.today + 62).strftime('%Y-%m-%d'),
      :myscout_programme_expires => (Date.today + 63).strftime('%Y-%m-%d'),
      :myscout_details_expires => (Date.today + 64),
      :myscout_events => true,
      :myscout_badges => true,
      :myscout_programme => true,
      :myscout_payments => true,
      :myscout_emails => {:email1 => true, :email2 => false},
      :myscout_email_address_from => 'send_from@example.com',
      :myscout_email_address_copy => '',
      :myscout_badges_partial => true,
      :myscout_programme_summary => true,
      :myscout_programme_times => true,
      :myscout_programme_show => 20,
      :myscout_event_reminder_count => 4,
      :myscout_event_reminder_frequency => 5,
      :myscout_payment_reminder_count => 6,
      :myscout_payment_reminder_frequency => 7,
      :myscout_details => true,
      :myscout_details_email_changes_to => 'notify-changes-to@example.com',
    }
  end


  it "Create" do
    section = Osm::Section.new(@attributes)

    section.id.should == 1
    section.name.should == 'Name' 
    section.subscription_level.should == 2
    section.subscription_expires.should == Date.today + 60
    section.type.should == :cubs
    section.group_id.should == 3
    section.group_name.should == '3rd Somewhere'
    section.flexi_records.should == []
    section.gocardless.should == true
    section.myscout_events_expires.should == Date.today + 61
    section.myscout_badges_expires.should == Date.today + 62
    section.myscout_programme_expires.should == Date.today + 63
    section.myscout_details_expires.should == Date.today + 64
    section.myscout_events.should == true
    section.myscout_badges.should == true
    section.myscout_programme.should == true
    section.myscout_payments.should == true
    section.myscout_emails.should == {:email1 => true, :email2 => false}
    section.myscout_email_address_from.should == 'send_from@example.com'
    section.myscout_email_address_copy.should == ''
    section.myscout_badges_partial.should == true
    section.myscout_programme_summary.should == true
    section.myscout_programme_times.should == true
    section.myscout_programme_show.should == 20
    section.myscout_event_reminder_count.should == 4
    section.myscout_event_reminder_frequency.should == 5
    section.myscout_payment_reminder_count.should == 6
    section.myscout_payment_reminder_frequency.should == 7
    section.myscout_details.should == true
    section.myscout_details_email_changes_to.should == 'notify-changes-to@example.com'
    section.valid?.should == true
  end


  it "Create has sensible defaults" do
    section = Osm::Section.new

    section.subscription_level.should == 1
    section.subscription_expires.should be_nil
    section.type.should == :unknown
    section.flexi_records.should == []
    section.myscout_email_address_from.should == ''
    section.myscout_email_address_copy.should == ''
    section.myscout_details_email_changes_to.should == ''
    section.myscout_programme_show.should == 0
  end


  describe "Using the API" do

    before :each do
      body = [
        {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Flexi Record 1\",\"extraid\":\"111\"}],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true},\"gocardless\":\"true\",\"portal\":{\"paymentRemindFrequency\":\"7\",\"paymentRemindCount\":\"6\",\"eventRemindFrequency\":\"5\",\"eventRemindCount\":\"4\",\"badgesPartial\":1,\"programmeTimes\":1,\"programmeShow\":\"10\",\"programmeSummary\":1,\"details\":1,\"contactNotificationEmail\":\"notify-changes-to@example.com\",\"emailAddress\":\"send_from@example.com\",\"emailAddressCopy\":null,\"payments\":1,\"badges\":1,\"emails\":{\"email1\":\"true\",\"email2\":\"false\"},\"events\":1,\"programme\":1},\"portalExpires\":{\"events\":\"2013-01-06\",\"eventsA\":1,\"badges\":\"2013-01-07\",\"badgesA\":1,\"programme\":\"2013-01-08\",\"programmeA\":1,\"details\":\"2013-01-09\",\"detailsA\":1},\"hasSentTestSMS\":true,\"sms_remaining\":8,\"sms_sent\":9}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
        {"sectionConfig"=>"{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false},\"hasSentTestSMS\":true,\"sms_remaining\":8,\"sms_sent\":9}", "groupname"=>"1st Somewhere", "groupid"=>"1", "groupNormalised"=>"1", "sectionid"=>"2", "sectionname"=>"Section 2", "section"=>"cubs", "isDefault"=>"0", "permissions"=>{"badge"=>100, "member"=>100, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}}
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json, :content_type => 'application/json')
    end

    describe "Gets all sections" do
      it "From OSM" do
        sections = Osm::Section.get_all(api: $api)
        sections.map{ |i| i.id }.should == [1, 2]
  
        section = sections[0]
        section.id.should == 1
        section.name.should == 'Section 1' 
        section.subscription_level.should == 1
        section.subscription_expires.should == Date.new(2013, 1, 5)
        section.type.should == :beavers
        section.group_id.should == 3
        section.group_name.should == '3rd Somewhere'
        section.flexi_records.size.should == 1
        section.flexi_records[0].id.should == 111
        section.flexi_records[0].name.should == 'Flexi Record 1'
        section.gocardless.should == true
        section.myscout_events_expires.should == Date.new(2013, 1, 6)
        section.myscout_badges_expires.should == Date.new(2013, 1, 7)
        section.myscout_programme_expires.should == Date.new(2013, 1, 8)
        section.myscout_programme_show.should == 10
        section.myscout_details_expires.should == Date.new(2013, 1, 9)
        section.myscout_events.should == true
        section.myscout_badges.should == true
        section.myscout_programme.should == true
        section.myscout_payments.should == true
        section.myscout_emails.should == {:email1 => true, :email2 => false}
        section.myscout_email_address_from.should == 'send_from@example.com'
        section.myscout_email_address_copy.should == ''
        section.myscout_badges_partial.should == true
        section.myscout_programme_summary.should == true
        section.myscout_programme_times.should == true
        section.myscout_event_reminder_count.should == 4
        section.myscout_event_reminder_frequency.should == 5
        section.myscout_payment_reminder_count.should == 6
        section.myscout_payment_reminder_frequency.should == 7
        section.myscout_details.should == true
        section.myscout_details_email_changes_to.should == 'notify-changes-to@example.com'
        section.valid?.should == true
      end

      it "From cache" do
        sections = Osm::Section.get_all(api: $api)
        $api.should_not_receive(:post_query)
        Osm::Section.get_all(api: $api).should == sections
      end
    end
  
    it "Gets a section" do
      section = Osm::Section.get(api: $api, id: 1)
      section.should_not be_nil
      section.id.should == 1
      section.valid?.should == true
    end


    it "Gets the section's notepad" do
      $api.should_receive(:post_query).with(path: 'api.php?action=getNotepads').and_return({"1" => "Section 1", "2" => "Section 2"})
      section = Osm::Section.new(:id => 1)
      section.get_notepad($api).should == 'Section 1'
    end

    it "Sets the section's notepad (success)" do
      $api.should_receive(:post_query).with(path: 'users.php?action=updateNotepad&sectionid=1', post_data: {"value"=>"content"}).and_return({"ok" => true})
      section = Osm::Section.new(:id => 1)
      section.set_notepad(api: $api, content: 'content').should == true
    end

    it "Sets the section's notepad (fail)" do
      $api.should_receive(:post_query).with(path: 'users.php?action=updateNotepad&sectionid=1', post_data: {"value"=>"content"}).and_return({"ok" => false})
      section = Osm::Section.new(:id => 1)
      section.set_notepad(api: $api, content: 'content').should == false
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


  it "Sorts by Group Name, section type (age order) then name" do
    section1 = Osm::Section.new(@attributes.merge(:group_id => 1, :group_name => '1st Somewhere', :type => :beavers, :name => 'a'))
    section2 = Osm::Section.new(@attributes.merge(:group_id => 2, :group_name => '2nd Somewhere', :type => :beavers, :name => 'a'))
    section3 = Osm::Section.new(@attributes.merge(:group_id => 2, :group_name => '2nd Somewhere', :type => :cubs, :name => 'a'))
    section4 = Osm::Section.new(@attributes.merge(:group_id => 2, :group_name => '2nd Somewhere', :type => :cubs, :name => 'b'))

    data = [section2, section4, section3, section1]
    data.sort.should == [section1, section2, section3, section4]
  end


  describe "Correctly works out the section type" do
    unknown   = Osm::Section.new(:type => :abc)
    beavers   = Osm::Section.new(:type => :beavers)
    cubs      = Osm::Section.new(:type => :cubs)
    scouts    = Osm::Section.new(:type => :scouts)
    explorers = Osm::Section.new(:type => :explorers)
    network   = Osm::Section.new(:type => :network)
    adults    = Osm::Section.new(:type => :adults)
    waiting   = Osm::Section.new(:type => :waiting)

    {:beavers => beavers, :cubs => cubs, :scouts => scouts, :explorers => explorers, :network => network, :adults => adults, :waiting => waiting, :unknown => unknown}.each do |section_type, section|
      it "For a #{section_type} section" do
        [:beavers, :cubs, :scouts, :explorers, :network, :adults, :waiting].each do |type|
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
    network =   Osm::Section.new(:type => :network)
    adults =    Osm::Section.new(:type => :adults)
    waiting =   Osm::Section.new(:type => :waiting)

    [beavers, cubs, scouts, explorers].each do |section|
      it "For a #{section.type} section" do
        section.youth_section?.should == true
      end
    end
    [network, adults, waiting, unknown].each do |section|
      it "For a #{section.type} section" do
        section.youth_section?.should == false
      end
    end
  end

  describe "Corretly works out the subscription level" do

    it "Bronze" do
      section = Osm::Section.new(subscription_level: 1)
      section.bronze?.should == true
      section.silver?.should == false
      section.gold?.should == false
      section.gold_plus?.should == false
    end

    it "Silver" do
      section = Osm::Section.new(subscription_level: 2)
      section.bronze?.should == false
      section.silver?.should == true
      section.gold?.should == false
      section.gold_plus?.should == false
    end

    it "Gold" do
      section = Osm::Section.new(subscription_level: 3)
      section.bronze?.should == false
      section.silver?.should == false
      section.gold?.should == true
      section.gold_plus?.should == false
    end

    it "Gold+" do
      section = Osm::Section.new(subscription_level: 4)
      section.bronze?.should == false
      section.silver?.should == false
      section.gold?.should == false
      section.gold_plus?.should == true
    end

    it "Unknown" do
      section = Osm::Section.new(subscription_level: 0)
      section.bronze?.should == false
      section.silver?.should == false
      section.gold?.should == false
      section.gold_plus?.should == false
    end

  end # describe

  describe "Correctly works out if a section has a subscription of at least" do

    it "Bronze" do
      section = Osm::Section.new(subscription_level: 1)
      section.subscription_at_least?(:bronze).should == true
      section.subscription_at_least?(:silver).should == false
      section.subscription_at_least?(:gold).should == false
      section.subscription_at_least?(:gold_plus).should == false
      section.subscription_at_least?(1).should == true
      section.subscription_at_least?(2).should == false
      section.subscription_at_least?(3).should == false
      section.subscription_at_least?(4).should == false
    end

    it "Silver" do
      section = Osm::Section.new(subscription_level: 2)
      section.subscription_at_least?(:bronze).should == true
      section.subscription_at_least?(:silver).should == true
      section.subscription_at_least?(:gold).should == false
      section.subscription_at_least?(:gold_plus).should == false
      section.subscription_at_least?(1).should == true
      section.subscription_at_least?(2).should == true
      section.subscription_at_least?(3).should == false 
      section.subscription_at_least?(4).should == false 
    end

    it "Gold" do
      section = Osm::Section.new(subscription_level: 3)
      section.subscription_at_least?(:bronze).should == true
      section.subscription_at_least?(:silver).should == true
      section.subscription_at_least?(:gold).should == true
      section.subscription_at_least?(:gold_plus).should == false
      section.subscription_at_least?(1).should == true
      section.subscription_at_least?(2).should == true
      section.subscription_at_least?(3).should == true 
      section.subscription_at_least?(4).should == false 
    end

    it "Gold+" do
      section = Osm::Section.new(subscription_level: 4)
      section.subscription_at_least?(:bronze).should == true
      section.subscription_at_least?(:silver).should == true
      section.subscription_at_least?(:gold).should == true
      section.subscription_at_least?(:gold_plus).should == true
      section.subscription_at_least?(1).should == true
      section.subscription_at_least?(2).should == true
      section.subscription_at_least?(3).should == true 
      section.subscription_at_least?(4).should == true 
    end

    it "Unknown" do
      section = Osm::Section.new(subscription_level: 0)
      section.subscription_at_least?(:bronze).should == false
      section.subscription_at_least?(:silver).should == false
      section.subscription_at_least?(:gold).should == false
      section.subscription_at_least?(:gold_plus).should == false
      section.subscription_at_least?(1).should == false
      section.subscription_at_least?(2).should == false
      section.subscription_at_least?(3).should == false 
      section.subscription_at_least?(4).should == false 
    end

  end # describe

end



describe "Online Scout Manager API Strangeness" do

  it "handles a section with no type" do
    body = '[{"sectionConfig":"{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member\'s Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member\'s Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Subs\",\"extraid\":\"529\"}],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}","groupname":"1st Somewhere","groupid":"1","groupNormalised":"1","sectionid":"1","sectionname":"Section 1","section":"cubs","isDefault":"1","permissions":{"badge":100,"member":100,"user":100,"register":100,"contact":100,"programme":100,"originator":1,"events":100,"finance":100,"flexi":100}}]'
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body, :content_type => 'application/json')

    sections = Osm::Section.get_all(api: $api)
    sections.size.should == 1
    section = sections[0]
    section.should_not be_nil
    section.type.should == :unknown
  end

  it "handles strange extra records when getting roles" do
    body = '[{"sectionConfig":"{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member\'s Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member\'s Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[[\"1\",{\"name\":\"Subs\",\"extraid\":\"529\"}],[\"2\",{\"name\":\"Subs 2\",\"extraid\":\"530\"}]],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}","groupname":"1st Somewhere","groupid":"1","groupNormalised":"1","sectionid":"1","sectionname":"Section 1","section":"cubs","isDefault":"1","permissions":{"badge":100,"member":100,"user":100,"register":100,"contact":100,"programme":100,"originator":1,"events":100,"finance":100,"flexi":100}}]'
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body, :content_type => 'application/json')

    sections = Osm::Section.get_all(api: $api)
    sections.size.should == 1
    sections[0].should_not be_nil
  end

  it "handles an empty array representing no notepads" do
    body = [{"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Flexi Record 1\",\"extraid\":\"111\"}],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}}]
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json, :content_type => 'application/json')
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getNotepads", :body => '[]', :content_type => 'application/json')

    section = Osm::Section.get(api: $api, id: 1)
    section.should_not be_nil
    section.get_notepad($api).should == ''
  end

  it "skips a 'discount' section" do
    body = [
      {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"1", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>100, "member"=>100, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
      {"sectionConfig"=>"{\"code\":1,\"districts\":[\"Loddon\",\"Kennet\"]}","groupname"=>"Berkshire","groupid"=>"2","groupNormalised"=>"1","sectionid"=>"3","sectionname"=>"County Admin","section"=>"discount","isDefault"=>"0","permissions"=>{"districts"=>["Loddon"]}}
    ]
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json, :content_type => 'application/json')

    sections = Osm::Section.get_all(api: $api)
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
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json, :content_type => 'application/json')

    sections = Osm::Section.get_all(api: $api)
    sections.size.should == 2
    sections[0].should_not be_nil
    sections[1].should_not be_nil
  end

  it "Handles user having access to no sections" do
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => '[{"isDefault":"1"}]', :content_type => 'application/json')

    sections = Osm::Section.get_all(api: $api)
    sections.should == []
  end

end
