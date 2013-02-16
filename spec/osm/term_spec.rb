# encoding: utf-8
require 'spec_helper'
require 'date'

describe "Term" do

  before :each do
    @attributes = {
      :id => 1,
      :section_id => 2,
      :name => 'Term name',
      :start => Date.new(2001, 01, 01),
      :finish => Date.new(2001, 03, 31)
    }
  end

  it "Create" do
    term = Osm::Term.new(@attributes)

    term.id.should == 1
    term.section_id.should == 2
    term.name.should == 'Term name'
    term.start.should == Date.new(2001, 1, 1)
    term.finish.should == Date.new(2001, 3, 31)
    term.valid?.should be_true
  end

  it "Compares two matching terms" do
    term1 = Osm::Term.new(@attributes)
    term2 = Osm::Term.new(@attributes)
    term1.should == term2
  end

  it "Compares two non-matching terms" do
    term = Osm::Term.new(@attributes)

    term.should_not == Osm::Term.new(@attributes.merge(:id => 3))
  end

  it "Sorts by Section ID, Start date and th Term ID" do
    term1 = Osm::Term.new(@attributes.merge(:section_id => 1, :term => 11, :start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:section_id => 1, :term => 12, :start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:section_id => 1, :term => 13, :start => (Date.today +  1), :finish => (Date.today + 60)))
    term4 = Osm::Term.new(@attributes.merge(:section_id => 2, :term => 1, :start => (Date.today +  1), :finish => (Date.today + 60)))
    term5 = Osm::Term.new(@attributes.merge(:section_id => 2, :term => 2, :start => (Date.today +  1), :finish => (Date.today + 60)))

    data = [term5, term3, term2, term4, term1]
    data.sort.should == [term1, term2, term3, term4, term5]
  end

  it "Works out if it is completly before a date" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.before?(Date.today).should == true
    term2.before?(Date.today).should == false
    term3.before?(Date.today).should == false
  end

  it "Works out if it is completly after a date" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.after?(Date.today).should == false
    term2.after?(Date.today).should == false
    term3.after?(Date.today).should == true
  end

  it "Works out if it has passed" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.past?().should == true
    term2.past?().should == false
    term3.past?().should == false
  end

  it "Works out if it is in the future" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.future?().should == false
    term2.future?().should == false
    term3.future?().should == true
  end

  it "Works out if it is the current term" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start=> (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.current?().should == false
    term2.current?().should == true
    term3.current?().should == false
  end

  it "Works out if it contains a date" do
    term1 = Osm::Term.new(@attributes.merge(:start => (Date.today - 60), :finish => (Date.today - 1)))
    term2 = Osm::Term.new(@attributes.merge(:start => (Date.today -  0), :finish => (Date.today + 0)))
    term3 = Osm::Term.new(@attributes.merge(:start => (Date.today +  1), :finish => (Date.today + 60)))

    term1.contains_date?(Date.today).should == false
    term2.contains_date?(Date.today).should == true
    term3.contains_date?(Date.today).should == false
  end


  describe "Using the API" do

    before :each do
      body = [
        {"sectionConfig"=>"{\"subscription_level\":1,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"beavers\",\"columnNames\":{\"column_names\":\"names\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[{\"name\":\"Flexi Record 1\",\"extraid\":\"111\"}],\"wizard\":\"false\",\"fields\":{\"fields\":true},\"intouch\":{\"intouch_fields\":true},\"mobFields\":{\"mobile_fields\":true}}", "groupname"=>"3rd Somewhere", "groupid"=>"3", "groupNormalised"=>"1", "sectionid"=>"9", "sectionname"=>"Section 1", "section"=>"beavers", "isDefault"=>"1", "permissions"=>{"badge"=>10, "member"=>20, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}},
        {"sectionConfig"=>"{\"subscription_level\":3,\"subscription_expires\":\"2013-01-05\",\"sectionType\":\"cubs\",\"columnNames\":{\"phone1\":\"Home Phone\",\"phone2\":\"Parent 1 Phone\",\"address\":\"Member's Address\",\"phone3\":\"Parent 2 Phone\",\"address2\":\"Address 2\",\"phone4\":\"Alternate Contact Phone\",\"subs\":\"Gender\",\"email1\":\"Parent 1 Email\",\"medical\":\"Medical / Dietary\",\"email2\":\"Parent 2 Email\",\"ethnicity\":\"Gift Aid\",\"email3\":\"Member's Email\",\"religion\":\"Religion\",\"email4\":\"Email 4\",\"school\":\"School\"},\"numscouts\":10,\"hasUsedBadgeRecords\":true,\"hasProgramme\":true,\"extraRecords\":[],\"wizard\":\"false\",\"fields\":{\"email1\":true,\"email2\":true,\"email3\":true,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":true,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":true,\"saved\":true},\"intouch\":{\"address\":true,\"address2\":false,\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"medical\":false},\"mobFields\":{\"email1\":false,\"email2\":false,\"email3\":false,\"email4\":false,\"address\":true,\"address2\":false,\"phone1\":true,\"phone2\":true,\"phone3\":true,\"phone4\":true,\"school\":false,\"religion\":false,\"ethnicity\":true,\"medical\":true,\"patrol\":true,\"subs\":false}}", "groupname"=>"1st Somewhere", "groupid"=>"1", "groupNormalised"=>"1", "sectionid"=>"10", "sectionname"=>"Section 2", "section"=>"cubs", "isDefault"=>"0", "permissions"=>{"badge"=>100, "member"=>100, "user"=>100, "register"=>100, "contact"=>100, "programme"=>100, "originator"=>1, "events"=>100, "finance"=>100, "flexi"=>100}}
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json)

      body = {
        "9" => [
          {"termid" => "1", "name" => "Term 1", "sectionid" => "9", "startdate" => (Date.today + 31).strftime('%Y-%m-%d'), "enddate" => (Date.today + 90).strftime('%Y-%m-%d')}
        ],
        "10" => [
          {"termid" => "2", "name" => "Term 2", "sectionid" => "10", "startdate" => (Date.today + 31).strftime('%Y-%m-%d'), "enddate" => (Date.today + 90).strftime('%Y-%m-%d')},
          {"termid" => "3", "name" => "Term 3", "sectionid" => "10", "startdate" => (Date.today + 91).strftime('%Y-%m-%d'), "enddate" => (Date.today + 180).strftime('%Y-%m-%d')}
        ]
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getTerms", :body => body.to_json)
    end


    describe "Get all terms" do
      it "From OSM" do
        terms = Osm::Term.get_all(@api)
        terms.size.should == 3
        terms.map{ |i| i.id }.should == [1, 2, 3]
        term = terms[0]
        term.is_a?(Osm::Term).should be_true
        term.id.should == 1
        term.name.should == 'Term 1'
        term.start.should == (Date.today + 31)
        term.finish.should == (Date.today + 90)
      end

      it "From cache" do
        terms = Osm::Term.get_all(@api)
        HTTParty.should_not_receive(:post)
        Osm::Term.get_all(@api).should == terms
      end
    end

    it "Gets all terms for a section" do
      terms = Osm::Term.get_for_section(@api, 10)
      terms.size.should == 2
      terms.map{ |i| i.id }.should == [2, 3]
    end

    it "Gets a term" do
      term = Osm::Term.get(@api, 2)
      term.is_a?(Osm::Term).should be_true
      term.id.should == 2
    end

    describe "find current term" do
      it "Returns the current term for the section from all terms returned by OSM" do
        body = '{"9":['
        body += '{"termid":"1","name":"Term 1","sectionid":"9","startdate":"' + (Date.today - 90).strftime('%Y-%m-%d') + '","enddate":"' + (Date.today - 31).strftime('%Y-%m-%d') + '"},'
        body += '{"termid":"2","name":"Term 2","sectionid":"9","startdate":"' + (Date.today - 30).strftime('%Y-%m-%d') + '","enddate":"' + (Date.today + 30).strftime('%Y-%m-%d') + '"},'
        body += '{"termid":"3","name":"Term 3","sectionid":"9","startdate":"' + (Date.today + 31).strftime('%Y-%m-%d') + '","enddate":"' + (Date.today + 90).strftime('%Y-%m-%d') + '"}'
        body += ']}'
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getTerms", :body => body)
    
        Osm::Term.get_current_term_for_section(@api, 9).id.should == 2
      end
    
      it "Raises an error if there is no current term" do
        body = '{"9":['
        body += '{"termid":"1","name":"Term 1","sectionid":"9","startdate":"' + (Date.today + 31).strftime('%Y-%m-%d') + '","enddate":"' + (Date.today + 90).strftime('%Y-%m-%d') + '"}'
        body += ']}'
        FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getTerms", :body => body)
    
        expect{ Osm::Term.get_current_term_for_section(@api, 9) }.to raise_error(Osm::Error, 'There is no current term for the section.')
      end
    end

    it "Create a term" do
      url = 'https://www.onlinescoutmanager.co.uk/users.php?action=addTerm&sectionid=1'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'term' => 'A Term',
        'start' => '2010-01-01',
        'end' => '2010-12-31',
        'termid' => '0'
      }

      Osm::Term.stub(:get_all) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"terms":{}}'}) }

      Osm::Term.create(@api, {
        :section => 1,
        :name => 'A Term',
        :start => Date.new(2010, 01, 01),
        :finish => Date.new(2010, 12, 31),
      }).should be_true
    end

    it "Create a term (failed)" do
      url = 'https://www.onlinescoutmanager.co.uk/users.php?action=addTerm&sectionid=1'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'term' => 'A Term',
        'start' => '2010-01-01',
        'end' => '2010-12-31',
        'termid' => '0'
      }

      Osm::Term.stub(:get_all) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }

      Osm::Term.create(@api, {
        :section => 1,
        :name => 'A Term',
        :start => Date.new(2010, 01, 01),
        :finish => Date.new(2010, 12, 31),
      }).should be_false
    end

    it "Update a term" do
      url = 'https://www.onlinescoutmanager.co.uk/users.php?action=addTerm&sectionid=1'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'term' => 'A Term',
        'start' => '2010-01-01',
        'end' => '2010-12-31',
        'termid' => 2
      }
      Osm::Term.stub(:get_all) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"terms":{}}'}) }

      term = Osm::Term.new(:id=>2, :section_id=>1, :name=>'A Term', :start=>Date.new(2010, 01, 01), :finish=>Date.new(2010, 12, 31))
      term.update(@api).should be_true
    end

    it "Update a term (failed)" do
      url = 'https://www.onlinescoutmanager.co.uk/users.php?action=addTerm&sectionid=1'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'term' => 'A Term',
        'start' => '2010-01-01',
        'end' => '2010-12-31',
        'termid' => 2
      }
      Osm::Term.stub(:get_all) { [] }
      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{}'}) }

      term = Osm::Term.new(:id=>2, :section_id=>1, :name=>'A Term', :start=>Date.new(2010, 01, 01), :finish=>Date.new(2010, 12, 31))
      term.update(@api).should be_false
    end

    it "Update a term (invalid term)" do
      term = Osm::Term.new
      expect{ term.update(@api) }.to raise_error(Osm::ObjectIsInvalid)
    end

  end

end
