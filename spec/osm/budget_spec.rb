# encoding: utf-8
require 'spec_helper'


describe "Budget" do

  it "Create Budget" do
    b = Osm::Budget.new(
      :id => 1,
      :section_id => 2,
      :name => 'Name',
    )

    b.id.should == 1
    b.section_id.should == 2
    b.name.should == 'Name'
    b.valid?.should == true
  end

  it "Sorts Budget by section ID then name" do
    b1 = Osm::Budget.new(:section_id => 1, :name => 'a')
    b2 = Osm::Budget.new(:section_id => 2, :name => 'a')
    b3 = Osm::Budget.new(:section_id => 2, :name => 'b')

    data = [b2, b3, b1]
    data.sort.should == [b1, b2, b3]
  end


  describe "Using the API" do

    it "Get budgets for section" do
      data = {
        "identifier" => "categoryid",
        "items" => [
          {
            "categoryid" => "2",
            "sectionid" => "3",
            "name" => "Name",
            "archived" => "1"
          }
        ]
      }
      $api.should_receive(:post_query).with(path: 'finances.php?action=getCategories&sectionid=3').and_return(data)

      budgets = Osm::Budget.get_for_section(api: $api, section: 3)
      budgets.should == [Osm::Budget.new(:id => 2, :section_id => 3, :name => 'Name')]
    end

    it "Create budget (success)" do
      budget = Osm::Budget.new(
        :section_id => 2,
        :name => 'Budget Name',
      )

      Osm::Budget.should_receive(:get_for_section).with(api: $api, section: 2, no_read_cache: true).and_return([Osm::Budget.new(:id => 3, :section_id => 2, :name => 'Existing budget'), Osm::Budget.new(:id => 4, :section_id => 2, :name => '** Unnamed **')])
      $api.should_receive(:post_query).with(path: 'finances.php?action=addCategory&sectionid=2').and_return({'ok'=>true})
      $api.should_receive(:post_query).with(path: 'finances.php?action=updateCategory&sectionid=2', post_data: {
        'categoryid' => 4,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0,
      }).and_return({'ok'=>true})

      budget.create($api).should == true
      budget.id.should == 4
    end

    it "Create budget (failure (not created))" do
      budget = Osm::Budget.new(
        :section_id => 2,
        :name => 'Budget Name',
      )
    
      $api.should_receive(:post_query).with(path: 'finances.php?action=addCategory&sectionid=2').and_return({'ok'=>true})
      Osm::Budget.should_receive(:get_for_section).with(api: $api, section: 2, no_read_cache: true).and_return([Osm::Budget.new(:id => 3, :section_id => 2, :name => 'Existing budget')])

      budget.create($api).should == false
    end
    
    it "Create budget (failure (not updated))" do
      budget = Osm::Budget.new(
        :section_id => 2,
        :name => 'Budget Name',
      )
    
      Osm::Budget.should_receive(:get_for_section).with(api: $api, section: 2, no_read_cache: true).and_return([Osm::Budget.new(:id => 3, :section_id => 2, :name => '** Unnamed **')])
      $api.should_receive(:post_query).with(path: 'finances.php?action=addCategory&sectionid=2').and_return({'ok'=>true})
      $api.should_receive(:post_query).with(path: 'finances.php?action=updateCategory&sectionid=2', post_data: {
        'categoryid' => 3,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0,
      }).and_return({'ok'=>false})

      budget.create($api).should == false
    end
    
    it "Update budget (success)" do
      budget = Osm::Budget.new(
        :id => 1,
        :section_id => 2,
        :name => 'Budget Name',
      )

      $api.should_receive(:post_query).with(path: 'finances.php?action=updateCategory&sectionid=2', post_data: {
        'categoryid' => 1,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0,
      }).and_return({'ok'=>true})
    
      budget.update($api).should == true
    end
    
    it "Update budget (failure)" do
      budget = Osm::Budget.new(
        :id => 1,
        :section_id => 2,
        :name => 'Budget Name',
      )

      $api.should_receive(:post_query).with(path: 'finances.php?action=updateCategory&sectionid=2', post_data: {
        'categoryid' => 1,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0,
      }).and_return({'ok'=>false})
    
      budget.update($api).should == false
    end
    
    it "Delete budget (success)" do
      budget = Osm::Budget.new(
        :id => 1,
        :section_id => 2,
        :name => 'Budget Name',
      )

      $api.should_receive(:post_query).with(path: 'finances.php?action=deleteCategory&sectionid=2', post_data: {'categoryid' => 1}).and_return({'ok'=>true})

      budget.delete($api).should == true
    end
    
    it "Delete budget (failure)" do
      budget = Osm::Budget.new(
        :id => 1,
        :section_id => 2,
        :name => 'Budget Name',
      )

      $api.should_receive(:post_query).with(path: 'finances.php?action=deleteCategory&sectionid=2', post_data: {'categoryid' => 1}).and_return({'ok'=>false})
    
      budget.delete($api).should == false
    end
    
  end


end
