# encoding: utf-8
require 'spec_helper'

describe "My.SCOUT" do

  describe "Parent login history" do

    it "Get from OSM" do
      @api.should_receive(:perform_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1'){
        {'items' => [
          {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>'16/04/2016 17:49'},
          {"scoutid"=>"3","firstname"=>"Jane","lastname"=>"Jones","numlogins"=>1,"lastlogin"=>'10/11/2015 14:21'},
        ]}
      }
      
      histories = Osm::Myscout::ParentLoginHistory.get_for_section(@api, 1)
      histories.size.should == 2
      histories[0].member_id.should == 2
      histories[0].first_name.should == 'John'
      histories[0].last_name.should == 'Smith'
      histories[0].logins.should == 271
      histories[0].last_login.should == Time.new(2016, 4, 16, 17, 49)
      histories[1].member_id.should == 3
      histories[1].first_name.should == 'Jane'
      histories[1].last_name.should == 'Jones'
      histories[1].logins.should == 1
      histories[1].last_login.should == Time.new(2015, 11, 10, 14, 21)
    end

    it 'Handles a last_login of "Invitation not sent"' do
      @api.should_receive(:perform_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1'){
        {'items' => [
          {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>'Invitation not sent'},
        ]}
      }
      
      history = Osm::Myscout::ParentLoginHistory.get_for_section(@api, 1)[0]
      history.last_login.should be_nil
    end

    it 'Handles a nil last_login' do
      @api.should_receive(:perform_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1'){
        {'items' => [
          {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>nil},
        ]}
      }
      
      history = Osm::Myscout::ParentLoginHistory.get_for_section(@api, 1)[0]
      history.last_login.should be_nil
    end

  end # describe ParentLoginHistory

end
