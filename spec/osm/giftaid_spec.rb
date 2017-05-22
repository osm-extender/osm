# encoding: utf-8
require 'spec_helper'
require 'date'


describe "Gift Aid" do

  it "Create Donation" do
    d = Osm::GiftAid::Donation.new(
      donation_date: Date.new(2000, 1, 2),
    )

    expect(d.donation_date).to eq(Date.new(2000, 1, 2))
    expect(d.valid?).to eq(true)
  end

  it "Sorts Donation by date" do
    d1 = Osm::GiftAid::Donation.new(donation_date: Date.new(2000, 1, 2))
    d2 = Osm::GiftAid::Donation.new(donation_date: Date.new(2001, 1, 2))

    data = [d2, d1]
    expect(data.sort).to eq([d1, d2])
  end


  it "Create Data" do
    d = Osm::GiftAid::Data.new(
      member_id: 1,
      first_name: 'A',
      last_name: 'B',
      tax_payer_name: 'C',
      tax_payer_address: 'D',
      tax_payer_postcode: 'E',
      section_id: 2,
      grouping_id: 3,
      total: '2.34',
      donations: {
        Date.new(2012, 1, 2) => '1.23',
      }
    )

    expect(d.member_id).to eq(1)
    expect(d.section_id).to eq(2)
    expect(d.grouping_id).to eq(3)
    expect(d.first_name).to eq('A')
    expect(d.last_name).to eq('B')
    expect(d.tax_payer_name).to eq('C')
    expect(d.tax_payer_address).to eq('D')
    expect(d.tax_payer_postcode).to eq('E')
    expect(d.total).to eq('2.34')
    expect(d.donations).to eq({
      Date.new(2012, 1, 2) => '1.23',
    })
    expect(d.valid?).to eq(true)
  end

  it "Sorts Data by section_id, grouping_id, last_name then first_name" do
    d1 = Osm::GiftAid::Data.new(section_id: 1, grouping_id: 1, last_name: 'a', first_name: 'a')
    d2 = Osm::GiftAid::Data.new(section_id: 2, grouping_id: 1, last_name: 'a', first_name: 'a')
    d3 = Osm::GiftAid::Data.new(section_id: 2, grouping_id: 2, last_name: 'a', first_name: 'a')
    d4 = Osm::GiftAid::Data.new(section_id: 2, grouping_id: 2, last_name: 'b', first_name: 'a')
    d5 = Osm::GiftAid::Data.new(section_id: 2, grouping_id: 2, last_name: 'b', first_name: 'b')

    data = [d4, d3, d5, d2, d1]
    expect(data.sort).to eq([d1, d2, d3, d4, d5])
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
      expect($api).to receive(:post_query).with('giftaid.php?action=getStructure&sectionid=1&termid=2').and_return(data)

      donations = Osm::GiftAid.get_donations(api: $api, section: 1, term: 2)
      expect(donations).to eq([Osm::GiftAid::Donation.new(donation_date: Date.new(2000, 1, 2))])
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
      expect($api).to receive(:post_query).with('giftaid.php?action=getGrid&sectionid=1&termid=2').and_return(data)

      data = Osm::GiftAid.get_data(api: $api, section: 1, term: 2)
      expect(data.is_a?(Array)).to eq(true)
      expect(data.size).to eq(1)
      data = data[0]
      expect(data.donations).to eq({
        Date.new(2000, 1, 2) => '1.23',
      })
      expect(data.first_name).to eq('First')
      expect(data.last_name).to eq('Last')
      expect(data.tax_payer_name).to eq('Tax')
      expect(data.grouping_id).to eq(3)
      expect(data.member_id).to eq(2)
      expect(data.total).to eq('2.34')
      expect(data.section_id).to eq(1)
      expect(data.valid?).to eq(true)
    end

    it "Update donation" do
      post_data = {
        'scouts' => '["3", "4"]',
        'donatedate'=> '2000-01-02',
        'amount' => '1.23',
        'notes' => 'Note',
        'sectionid' => 1,
      }
      expect($api).to receive(:post_query).with('giftaid.php?action=update&sectionid=1&termid=2', post_data: post_data).and_return([])

      expect(Osm::GiftAid.update_donation(
        api: $api,
        section: 1,
        term: 2,
        date: Date.new(2000, 1, 2),
        members: [3, 4],
        amount: '1.23',
        note: 'Note',
      )).to eq(true)
    end

    describe "Update data" do

      before :each do
        @data = Osm::GiftAid::Data.new(
          member_id: 1,
          first_name: 'A',
          last_name: 'B',
          tax_payer_name: 'C',
          tax_payer_address: 'D',
          tax_payer_postcode: 'E',
          section_id: 2,
          grouping_id: 3,
          total: '2.34',
          donations: {
            Date.new(2012, 1, 2) => '1.23',
            Date.new(2012, 1, 3) => '2.34',
          }
        )
        allow(Osm::Term).to receive(:get_current_term_for_section) { Osm::Term.new(id: 4) }
      end

      it "Tax payer" do
        post_data = {
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
        expect($api).to receive(:post_query).with('giftaid.php?action=updateScout', post_data: post_data.merge({'column' => 'parentname', 'value' => 'n'})).and_return(body_data)
        expect($api).to receive(:post_query).with('giftaid.php?action=updateScout', post_data: post_data.merge({'column' => 'address', 'value' => 'a'})).and_return(body_data)
        expect($api).to receive(:post_query).with('giftaid.php?action=updateScout', post_data: post_data.merge({'column' => 'postcode', 'value' => 'pc'})).and_return(body_data)

        @data.tax_payer_name = 'n'
        @data.tax_payer_address = 'a'
        @data.tax_payer_postcode = 'pc'
        expect(@data.update($api)).to eq(true)
      end

      it "A donation" do
        post_data = {
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
        url = "https://www.onlinescoutmanager.co.uk/"
        expect($api).to receive(:post_query).with('giftaid.php?action=updateScout', post_data: post_data).and_return(body_data)

        @data.donations[Date.new(2012, 1, 3)] = '3.45'
        expect(@data.update($api)).to eq(true)
      end

    end # Describe update data

  end # Describe using the API

end
