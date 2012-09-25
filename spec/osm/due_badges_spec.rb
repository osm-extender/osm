# encoding: utf-8
require 'spec_helper'

describe "DueBadge" do

  it "Create from API data" do
    data = {
      'pending' => {
        'badge_name' => [
          {
            'scoutid' => '1',
            'firstname' => 'John',
            'lastname' => 'Doe',
            'level' => '',
            'extra' => '',
          }
        ],
        'staged_staged_participation' => [{
            'sid' => '2',
            'firstname' => 'Jane',
            'lastname' => 'Doe',
            'level' => '2',
            'extra' => 'Lvl 2'
          }, {
            'sid' => '1',
            'firstname' => 'John',
            'lastname' => 'Doe',
            'level' => '2',
            'extra' => 'Lvl 2'
          }
        ]
      },

      'description' => {
        'badge_name' => {
          'name' => 'Badge Name',
          'section' => 'cubs',
          'type' => 'activity',
          'badge' => 'badge_name'
        },
        'staged_staged_participation' => {
          'name' => 'Participation',
          'section' => 'staged',
          'type' => 'staged',
          'badge' => 'participation'
        }
      }
    }
    db = Osm::DueBadges.from_api(data)

    db.empty?.should == false
    db.descriptions.should == {'badge_name_1'=>'Badge Name', 'staged_staged_participation_2'=>'Participation (Level 2)'}
    db.by_member.should == {'John Doe'=>['badge_name_1', 'staged_staged_participation_2'], 'Jane Doe'=>['staged_staged_participation_2']}
    db.totals.should == {'staged_staged_participation_2'=>2, 'badge_name_1'=>1}
    db.valid?.should be_true
  end

end