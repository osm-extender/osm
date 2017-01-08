# encoding: utf-8
require 'spec_helper'

describe "My.SCOUT" do

  describe "Parent login history" do

    it "Get from OSM" do
      data = {'items' => [
        {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>'16/04/2016 17:49'},
        {"scoutid"=>"3","firstname"=>"Jane","lastname"=>"Jones","numlogins"=>1,"lastlogin"=>'10/11/2015 14:21'},
      ]}
      $api.should_receive(:post_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1').and_return(data)
      
      histories = Osm::Myscout::ParentLoginHistory.get_for_section(api: $api, section: 1)
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
      data = {'items' => [
        {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>'Invitation not sent'},
      ]}

      $api.should_receive(:post_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1').and_return(data)
      
      history = Osm::Myscout::ParentLoginHistory.get_for_section(api: $api, section: 1)[0]
      history.last_login.should be_nil
    end

    it 'Handles a nil last_login' do
      data = {'items' => [
        {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>nil},
      ]}
      $api.should_receive(:post_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1').and_return(data)

      history = Osm::Myscout::ParentLoginHistory.get_for_section(api: $api, section: 1)[0]
      history.last_login.should be_nil
    end

  end # describe ParentLoginHistory


  describe "Template" do

    describe "Get" do

      it "Success" do
        $api.should_receive(:post_query).with('ext/settings/parents/?action=getTemplate&key=email-first&section_id=1').and_return({"status"=>true, "error"=>nil, "data"=>"TEMPLATE GOES HERE", "meta"=>[]})
        Osm::Myscout::Template.get_template(api: $api, section: 1, key: 'email-first').should == 'TEMPLATE GOES HERE'
      end

      it "Failed" do
        $api.should_receive(:post_query).with('ext/settings/parents/?action=getTemplate&key=email-first&section_id=1').and_return({"status"=>false, "error"=>nil, "data"=>"", "meta"=>[]})
        Osm::Myscout::Template.get_template(api: $api, section: 1, key: 'email-first').should be_nil
      end

    end

    describe "Update" do

      it "Success" do
        template = 'CONTENT WHICH CONTAINS [DIRECT_LINK].'
        $api.should_receive(:post_query).with('ext/settings/parents/?action=updateTemplate', post_data: {'section_id'=>1, 'key'=>'email-invitation', 'value'=>template}).and_return({"status"=>true, "error"=>nil, "data"=>true, "meta"=>[]})
        Osm::Myscout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: template).should be true
      end

      it "Failed" do
        template = 'CONTENT WHICH CONTAINS [DIRECT_LINK].'
        $api.should_receive(:post_query).with('ext/settings/parents/?action=updateTemplate', post_data: {'section_id'=>1, 'key'=>'email-invitation', 'value'=>template}).and_return({"status"=>false, "error"=>nil, "data"=>false, "meta"=>[]})
        Osm::Myscout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: template).should be false
      end

      it "Missing a required tag" do
        $api.should_not_receive(:post_query)
        expect{ Osm::Myscout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: 'CONTENT') }.to raise_error ArgumentError, 'Required tag [DIRECT_LINK] not found in template content.'
      end

    end

    describe "Restore" do

      it "Success" do
        $api.should_receive(:post_query).with('ext/settings/parents/?action=restoreTemplate', post_data: {'section_id'=>1, 'key'=>'email-first'}).and_return({"status"=>true, "error"=>nil, "data"=>"TEMPLATE GOES HERE", "meta"=>[]})
        Osm::Myscout::Template.restore_template(api: $api, section: 1, key: 'email-first').should == 'TEMPLATE GOES HERE'
      end

      it "Failed" do
        $api.should_receive(:post_query).with('ext/settings/parents/?action=restoreTemplate', post_data: {'section_id'=>1, 'key'=>'email-first'}).and_return({"status"=>false, "error"=>nil, "data"=>"TEMPLATE GOES HERE", "meta"=>[]})
        Osm::Myscout::Template.restore_template(api: $api, section: 1, key: 'email-first').should be_nil
      end

    end

  end # describe Template

end
