# encoding: utf-8
require 'spec_helper'

describe "My.SCOUT" do

  describe "Parent login history" do

    it "Get from OSM" do
      data = {'items' => [
        {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>'16/04/2016 17:49'},
        {"scoutid"=>"3","firstname"=>"Jane","lastname"=>"Jones","numlogins"=>1,"lastlogin"=>'10/11/2015 14:21'},
      ]}
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
      data = {'items' => [
        {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>'Invitation not sent'},
      ]}

      expect($api).to receive(:post_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1').and_return(data)
      
      history = Osm::MyScout::ParentLoginHistory.get_for_section(api: $api, section: 1)[0]
      expect(history.last_login).to be_nil
    end

    it 'Handles a nil last_login' do
      data = {'items' => [
        {"scoutid"=>"2","firstname"=>"John","lastname"=>"Smith","numlogins"=>271,"lastlogin"=>nil},
      ]}
      expect($api).to receive(:post_query).with('ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=1').and_return(data)

      history = Osm::MyScout::ParentLoginHistory.get_for_section(api: $api, section: 1)[0]
      expect(history.last_login).to be_nil
    end

  end # describe ParentLoginHistory


  describe "Template" do

    describe "Get" do

      it "Success" do
        expect($api).to receive(:post_query).with('ext/settings/parents/?action=getTemplate&key=email-first&section_id=1').and_return({"status"=>true, "error"=>nil, "data"=>"TEMPLATE GOES HERE", "meta"=>[]})
        expect(Osm::MyScout::Template.get_template(api: $api, section: 1, key: 'email-first')).to eq('TEMPLATE GOES HERE')
      end

      it "Failed" do
        expect($api).to receive(:post_query).with('ext/settings/parents/?action=getTemplate&key=email-first&section_id=1').and_return({"status"=>false, "error"=>nil, "data"=>"", "meta"=>[]})
        expect(Osm::MyScout::Template.get_template(api: $api, section: 1, key: 'email-first')).to be_nil
      end

    end

    describe "Update" do

      it "Success" do
        template = 'CONTENT WHICH CONTAINS [DIRECT_LINK].'
        expect($api).to receive(:post_query).with('ext/settings/parents/?action=updateTemplate', post_data: {'section_id'=>1, 'key'=>'email-invitation', 'value'=>template}).and_return({"status"=>true, "error"=>nil, "data"=>true, "meta"=>[]})
        expect(Osm::MyScout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: template)).to be true
      end

      it "Failed" do
        template = 'CONTENT WHICH CONTAINS [DIRECT_LINK].'
        expect($api).to receive(:post_query).with('ext/settings/parents/?action=updateTemplate', post_data: {'section_id'=>1, 'key'=>'email-invitation', 'value'=>template}).and_return({"status"=>false, "error"=>nil, "data"=>false, "meta"=>[]})
        expect(Osm::MyScout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: template)).to be false
      end

      it "Missing a required tag" do
        expect($api).not_to receive(:post_query)
        expect{ Osm::MyScout::Template.update_template(api: $api, section: 1, key: 'email-invitation', content: 'CONTENT') }.to raise_error ArgumentError, 'Required tag [DIRECT_LINK] not found in template content.'
      end

    end

    describe "Restore" do

      it "Success" do
        expect($api).to receive(:post_query).with('ext/settings/parents/?action=restoreTemplate', post_data: {'section_id'=>1, 'key'=>'email-first'}).and_return({"status"=>true, "error"=>nil, "data"=>"TEMPLATE GOES HERE", "meta"=>[]})
        expect(Osm::MyScout::Template.restore_template(api: $api, section: 1, key: 'email-first')).to eq('TEMPLATE GOES HERE')
      end

      it "Failed" do
        expect($api).to receive(:post_query).with('ext/settings/parents/?action=restoreTemplate', post_data: {'section_id'=>1, 'key'=>'email-first'}).and_return({"status"=>false, "error"=>nil, "data"=>"TEMPLATE GOES HERE", "meta"=>[]})
        expect(Osm::MyScout::Template.restore_template(api: $api, section: 1, key: 'email-first')).to be_nil
      end

    end

  end # describe Template

end
