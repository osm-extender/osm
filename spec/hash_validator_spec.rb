module HashValidatorSpec

  class KeyTypeTestModel
    include ActiveAttr::Model
    attribute :hash_attr
    validates :hash_attr, hash: {key_type: Integer}
  end

  class KeyInTestModel
    include ActiveAttr::Model
    attribute :hash_attr
    validates :hash_attr, hash: {key_in: [1, 2]}
  end

  class ValueTypeTestModel
    include ActiveAttr::Model
    attribute :hash_attr
    validates :hash_attr, hash: {value_type: Integer}
  end

  class ValueInTestModel
    include ActiveAttr::Model
    attribute :hash_attr
    validates :hash_attr, hash: {value_in: [1, 2]}
  end


  describe HashValidator do

    describe "Key type option" do

      it "Has only correct keys" do
        model = KeyTypeTestModel.new(hash_attr: {1=>'1', 2=>'2'})
        expect(model.valid?).to eq(true)
        expect(model.errors.count).to eq(0)
      end

      it "Has an incorrect key" do
        model = KeyTypeTestModel.new(hash_attr: {1=>'1', 2=>'2', '3'=>'3'})
        expect(model.valid?).to eq(false)
        expect(model.errors.count).to eq(1)
        expect(model.errors.messages).to eq({hash_attr: ['keys must be a Integer ("3" is not).']})
      end

      it "Has several incorrect keys" do
        model = KeyTypeTestModel.new(hash_attr: {1=>'1', 2=>'2', '3'=>'3', '4'=>'4'})
        expect(model.valid?).to eq(false)
        expect(model.errors.count).to eq(2)
        expect(model.errors.messages).to eq({hash_attr: ['keys must be a Integer ("3" is not).', 'keys must be a Integer ("4" is not).']})
      end

    end


    describe "Key in option" do

      it "Has only correct keys" do
        model = KeyInTestModel.new(hash_attr: {1=>'1', 2=>'2'})
        expect(model.valid?).to eq(true)
        expect(model.errors.count).to eq(0)
      end

      it "Has an incorrect key" do
        model = KeyInTestModel.new(hash_attr: {1=>'1', 2=>'2', 3=>'3'})
        expect(model.valid?).to eq(false)
        expect(model.errors.count).to eq(1)
        expect(model.errors.messages).to eq({hash_attr: ['keys must be in [1, 2] (3 is not).']})
      end

      it "Has several incorrect keys" do
        model = KeyInTestModel.new(hash_attr: {1=>'1', 2=>'2', 3=>'3', 4=>'4'})
        expect(model.valid?).to eq(false)
        expect(model.errors.count).to eq(2)
        expect(model.errors.messages).to eq({hash_attr: ['keys must be in [1, 2] (3 is not).', 'keys must be in [1, 2] (4 is not).']})
      end

    end


    describe "Value type option" do

      it "Has only correct keys" do
        model = ValueTypeTestModel.new(hash_attr: {'1'=>1, '2'=>2})
        expect(model.valid?).to eq(true)
        expect(model.errors.count).to eq(0)
      end

      it "Has an incorrect key" do
        model = ValueTypeTestModel.new(hash_attr: {'1'=>1, '2'=>2, '3'=>'3'})
        expect(model.valid?).to eq(false)
        expect(model.errors.count).to eq(1)
        expect(model.errors.messages).to eq({hash_attr: ['values must be a Integer ("3" for key "3" is not).']})
      end

      it "Has several incorrect keys" do
        model = ValueTypeTestModel.new(hash_attr: {'1'=>1, '2'=>2, '3'=>'3', '4'=>'4'})
        expect(model.valid?).to eq(false)
        expect(model.errors.count).to eq(2)
        expect(model.errors.messages).to eq({hash_attr: ['values must be a Integer ("3" for key "3" is not).', 'values must be a Integer ("4" for key "4" is not).']})
      end

    end


    describe "Value in option" do

      it "Has only correct keys" do
        model = ValueInTestModel.new(hash_attr: {'1'=>1, '2'=>2})
        expect(model.valid?).to eq(true)
        expect(model.errors.count).to eq(0)
      end

      it "Has an incorrect key" do
        model = ValueInTestModel.new(hash_attr: {'1'=>1, '2'=>2, '3'=>'3'})
        expect(model.valid?).to eq(false)
        expect(model.errors.count).to eq(1)
        expect(model.errors.messages).to eq({hash_attr: ['values must be in [1, 2] ("3" for key "3" is not).']})
      end

      it "Has several incorrect keys" do
        model = ValueInTestModel.new(hash_attr: {'1'=>1, '2'=>2, '3'=>'3', '4'=>'4'})
        expect(model.valid?).to eq(false)
        expect(model.errors.count).to eq(2)
        expect(model.errors.messages).to eq({hash_attr: ['values must be in [1, 2] ("3" for key "3" is not).', 'values must be in [1, 2] ("4" for key "4" is not).']})
      end

    end

  end

end
