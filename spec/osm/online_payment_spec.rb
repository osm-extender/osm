# encoding: utf-8
require 'spec_helper'

describe "Online payments" do

  describe "Schedule" do

    it "Create" do
      schedule = Osm::OnlinePayment::Schedule.new(
        id:             1,
        section_id:     2,
        account_id:     3,
        name:           'A payment schedule',
        description:    'What this payment schedule is used for',
        archived:       true,
        gift_aid:       true,
        require_all:    true,
        pay_now:        14,
        annual_limit:   '100',
        payments:       [],
      )
      schedule.id.should == 1
      schedule.section_id.should == 2
      schedule.account_id.should == 3
      schedule.name.should == 'A payment schedule'
      schedule.description.should == 'What this payment schedule is used for'
      schedule.archived.should == true
      schedule.gift_aid.should == true
      schedule.require_all.should == true
      schedule.pay_now.should == 14
      schedule.annual_limit.should == '100'
      schedule.payments.should == []
      schedule.valid?.should == true
    end

    it "Provides current payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new(payments: [payment1, payment2])
      schedule.current_payments.should == [payment1]
    end

    it "Checks for current payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new()

      schedule.payments = [payment1]
      schedule.current_payments?.should == true

      schedule.payments = [payment2]
      schedule.current_payments?.should == false
    end

    it "Provides archived payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new(payments: [payment1, payment2])
      schedule.archived_payments.should == [payment2]
    end

    it "Checks for archived payments" do
      payment1 = Osm::OnlinePayment::Schedule::Payment.new(id: 1, archived: false)
      payment2 = Osm::OnlinePayment::Schedule::Payment.new(id: 2, archived: true)
      schedule = Osm::OnlinePayment::Schedule.new()

      schedule.payments = [payment2]
      schedule.archived_payments?.should == true

      schedule.payments = [payment1]
      schedule.archived_payments?.should == false
    end

    it "Sorts by section_id, name then id" do
      schedule1 = Osm::OnlinePayment::Schedule.new(section_id: 1, name: 'A', id: 1)
      schedule2 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'A', id: 1)
      schedule3 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'B', id: 1)
      schedule4 = Osm::OnlinePayment::Schedule.new(section_id: 2, name: 'B', id: 2)
      schedules = [schedule3, schedule2, schedule4, schedule1]
      schedules.sort.should == [schedule1, schedule2, schedule3, schedule4]
    end

    it "Converts to a string" do
      schedule = Osm::OnlinePayment::Schedule.new(id: 1, name: 'Name')
      schedule.to_s.should == '1 -> Name'
    end


    describe "Uses OSM's API" do

      it "Gets summary list" do
        @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=getSchemes&sectionid=1'){ {'items'=>[{"schemeid"=>"539","name"=>"Events"}]} }
        result = Osm::OnlinePayment::Schedule.get_list_for_section(@api, 1)
        result.should == [{id: 539, name: 'Events'}]
      end

      it "Gets an individual schedule" do
        data = {"schemeid"=>"2","sectionid"=>"1","accountid"=>"3","name"=>"Schedule name","preauth_amount"=>"12.34","description"=>"Schedule description","giftaid"=>"1","defaulton"=>"1","paynow"=>"-1","archived"=>"1","payments"=>[{"paymentid"=>"4","schemeid"=>"2","date"=>"2013-03-21","amount"=>"1.23","name"=>"Payment name","archived"=>"1"}]}
        @api.should_receive(:perform_query).with('ext/finances/onlinepayments/?action=getPaymentSchedule&sectionid=1&schemeid=2&allpayments=true'){ data }
        schedule = Osm::OnlinePayment::Schedule.get(@api, 1, 2)
        schedule.id.should == 2
        schedule.section_id.should == 1
        schedule.account_id.should == 3
        schedule.name.should == 'Schedule name'
        schedule.description.should == 'Schedule description'
        schedule.archived.should == true
        schedule.gift_aid.should == true
        schedule.require_all.should == true
        schedule.pay_now.should == -1
        schedule.annual_limit.should == '12.34'
        schedule.payments.count.should == 1
        schedule.valid?.should == true
        payment = schedule.payments[0]
        payment.id.should == 4
        payment.amount.should == '1.23'
        payment.name.should == 'Payment name'
        payment.archived.should == true
        payment.due_date.should == Date.new(2013, 3, 21)
        payment.schedule.should == schedule
        payment.valid?.should == true
      end

      it "Gets all schedules for a section" do
        Osm::OnlinePayment::Schedule.should_receive(:get_list_for_section).with(@api, 5, {}){ [{id: 6, name: 'A'}, {id: 7, name: 'B'}] }
        Osm::OnlinePayment::Schedule.should_receive(:get).with(@api, 5, 6, {}){ 'A' }
        Osm::OnlinePayment::Schedule.should_receive(:get).with(@api, 5, 7, {}){ 'B' }
        Osm::OnlinePayment::Schedule.get_for_section(@api, 5).should == ['A', 'B']
      end

    end # describe Schedule : Uses OSM's API


    describe "Payment" do

      it "Create" do
        schedule = Osm::OnlinePayment::Schedule.new()
        schedule.stub('valid?'){ true }
        payment = Osm::OnlinePayment::Schedule::Payment.new(
          id:       1,
          amount:   '12.34',
          name:     'A payment',
          archived: true,
          due_date: Date.new(2016, 5, 1),
          schedule: schedule,
        )
        payment.id.should == 1
        payment.amount.should == '12.34'
        payment.name.should == 'A payment'
        payment.archived.should == true
        payment.due_date.should == Date.new(2016, 5, 1)
        payment.schedule.should == schedule
        payment.valid?.should == true
      end

      it "Checks if a payment is past due" do
        payment = Osm::OnlinePayment::Schedule::Payment.new(due_date: Date.new(2016, 5, 2))
        payment.past_due?(Date.new(2016, 5, 1)).should == false
        payment.past_due?(Date.new(2016, 5, 2)).should == false
        payment.past_due?(Date.new(2016, 5, 3)).should == true
      end

    end # describe Schedule -> Payment

  end # describe Schedule

end
