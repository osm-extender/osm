# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Gift Aid" do

  it "Create Donation" do
    d = Osm::GiftAid::Donation.new(
      :donation_date => Date.new(2000, 1, 2),
    )

    d.donation_date.should == Date.new(2000, 1, 2)
    d.valid?.should be_true
  end

  it "Sorts Donation by date" do
    d1 = Osm::GiftAid::Donation.new(:donation_date => Date.new(2000, 1, 2))
    d2 = Osm::GiftAid::Donation.new(:donation_date => Date.new(2001, 1, 2))

    data = [d2, d1]
    data.sort.should == [d1, d2]
  end


  it "Create Data" do
    d = Osm::GiftAid::Data.new(
      :member_id => 1,
      :first_name => 'A',
      :last_name => 'B',
      :tax_payer_name => 'C',
      :tax_payer_address => 'D',
      :tax_payer_postcode => 'E',
      :section_id => 2,
      :grouping_id => 3,
      :total => '2.34',
      :donations => {
        Date.new(2012, 1, 2) => '1.23',
      }
    )

    d.member_id.should == 1
    d.section_id.should == 2
    d.grouping_id.should == 3
    d.first_name.should == 'A'
    d.last_name.should == 'B'
    d.tax_payer_name.should == 'C'
    d.tax_payer_address.should == 'D'
    d.tax_payer_postcode.should == 'E'
    d.total.should == '2.34'
    d.donations.should == {
      Date.new(2012, 1, 2) => '1.23',
    }
    d.valid?.should be_true
  end

  it "Sorts Data by section_id, grouping_id, last_name then first_name" do
    d1 = Osm::GiftAid::Data.new(:section_id => 1, :grouping_id => 1, :last_name => 'a', :first_name => 'a')
    d2 = Osm::GiftAid::Data.new(:section_id => 2, :grouping_id => 1, :last_name => 'a', :first_name => 'a')
    d3 = Osm::GiftAid::Data.new(:section_id => 2, :grouping_id => 2, :last_name => 'a', :first_name => 'a')
    d4 = Osm::GiftAid::Data.new(:section_id => 2, :grouping_id => 2, :last_name => 'b', :first_name => 'a')
    d5 = Osm::GiftAid::Data.new(:section_id => 2, :grouping_id => 2, :last_name => 'b', :first_name => 'b')

    data = [d4, d3, d5, d2, d1]
    data.sort.should == [d1, d2, d3, d4, d5]
  end


  describe "Using the API" do

    it "Fetch the donations for a section" do
      data = [
	{"rows" => [
          {"name" => "First name","field" => "firstname","width" => "100px","formatter" => "boldFormatter"},
          {"name" => "Last name","field" => "lastname","width" => "100px","formatter" => "boldFormatter"},
          {"name" => "Tax payer's name","field" => "parentname","width" => "150px","editable" => true,"formatter" => "boldFormatter"},
          {"name" => "Total","field" => "total","width" => "60px","formatter" => "boldFormatter"}
	],"noscroll" => true},
	{"rows" => [
          {"name" => "2000-01-02", "field" => "2000-01-02", "width" => "110px", "editable" => true, "formatter" => "boldFormatter"}
	]}
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/giftaid.php?action=getStructure&sectionid=1&termid=2", :body => data.to_json, :content_type => 'application/json')

      donations = Osm::GiftAid.get_donations(@api, 1, 2)
      donations.should == [Osm::GiftAid::Donation.new(:donation_date => Date.new(2000, 1, 2))]
    end

    it "Fetch the data for a section" do
      data = {
	"identifier" => "scoutid",
	"label" => "name",
	"items" => [
	  {"2000-01-02" => "1.23", "total" => 2.34, "scoutid" => "2", "firstname" => "First", "lastname" => "Last", "patrolid" => "3", "parentname" => "Tax"},
	  {"2000-01-02" => 1.23,"firstname" => "TOTAL","lastname" => "","scoutid" => -1,"patrolid" => -1,"parentname" => "","total" => 1.23}
	]
      }

      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/giftaid.php?action=getGrid&sectionid=1&termid=2", :body => data.to_json, :content_type => 'application/json')

      data = Osm::GiftAid.get_data(@api, 1, 2)
      data.is_a?(Array).should be_true
      data.size.should == 1
      data = data[0]
      data.donations.should == {
        Date.new(2000, 1, 2) => '1.23',
      }
      data.first_name.should == 'First'
      data.last_name.should == 'Last'
      data.tax_payer_name.should == 'Tax'
      data.grouping_id.should == 3
      data.member_id.should == 2
      data.total.should == '2.34'
      data.section_id.should == 1
      data.valid?.should be_true
    end

    it "Update donation" do
      url = 'https://www.onlinescoutmanager.co.uk/giftaid.php?action=update&sectionid=1&termid=2'
      post_data = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'scouts' => '["3", "4"]',
        'donatedate'=> '2000-01-02',
        'amount' => '1.23',
        'notes' => 'Note',
        'sectionid' => 1,
      }

      HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'[]'}) }
      Osm::GiftAid.update_donation({
        :api => @api,
        :section => 1,
        :term => 2,
        :donation_date => Date.new(2000, 1, 2),
        :attendance => :yes,
        :members => [3, 4],
        :amount => '1.23',
        :note => 'Note',
      }).should be_true
    end

    describe "Update data" do

      before :each do
        @data = Osm::GiftAid::Data.new(
          :member_id => 1,
          :first_name => 'A',
          :last_name => 'B',
          :tax_payer_name => 'C',
          :tax_payer_address => 'D',
          :tax_payer_postcode => 'E',
          :section_id => 2,
          :grouping_id => 3,
          :total => '2.34',
          :donations => {
            Date.new(2012, 1, 2) => '1.23',
            Date.new(2012, 1, 3) => '2.34',
          }
        )
        Osm::Term.stub(:get_current_term_for_section) { Osm::Term.new(:id => 4) }
      end

      it "Tax payer" do
        post_data = {
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
          'scoutid' => 1,
          'termid' => 4,
          'sectionid' => 2,
          'row' => 0,
        }
        body_data = {
          "items" => [
            {"parentname" => "n", "address" => "a", "postcode" => "pc", "scoutid" => "1"},
            {"firstname" => "TOTAL","lastname" => "","scoutid" => -1,"patrolid" => -1,"parentname" => "","total" => 0}
          ]
        }
        url = "https://www.onlinescoutmanager.co.uk/giftaid.php?action=updateScout"
        HTTParty.should_receive(:post).with(url, {:body => post_data.merge({'column' => 'parentname', 'value' => 'n'})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>body_data.to_json}) }
        HTTParty.should_receive(:post).with(url, {:body => post_data.merge({'column' => 'address', 'value' => 'a'})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>body_data.to_json}) }
        HTTParty.should_receive(:post).with(url, {:body => post_data.merge({'column' => 'postcode', 'value' => 'pc'})}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>body_data.to_json}) }

        @data.tax_payer_name = 'n'
        @data.tax_payer_address = 'a'
        @data.tax_payer_postcode = 'pc'
        @data.update(@api).should be_true
      end

      it "A donation" do
        post_data = {
          'apiid' => @CONFIGURATION[:api][:osm][:id],
          'token' => @CONFIGURATION[:api][:osm][:token],
          'userid' => 'user_id',
          'secret' => 'secret',
          'scoutid' => 1,
          'termid' => 4,
          'column' => '2012-01-03',
          'value' => '3.45',
          'sectionid' => 2,
          'row' => 0,
        }
        body_data = {
          "items" => [
            {"2012-01-03" => "3.45","scoutid" => "1"},
            {"firstname" => "TOTAL","lastname" => "","scoutid" => -1,"patrolid" => -1,"parentname" => "","total" => 0}
          ]
        }
        url = "https://www.onlinescoutmanager.co.uk/giftaid.php?action=updateScout"
        HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>body_data.to_json}) }

        @data.donations[Date.new(2012, 1, 3)] = '3.45'
        @data.update(@api).should be_true
      end

    end

  end

end
