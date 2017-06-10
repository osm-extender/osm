module ValidityValidatorSpec
  class TestItem
    include ActiveAttr::Model
    attribute :validity
    validates_inclusion_of :validity, in: [true]
  end

  class TestModel
    include ActiveAttr::Model
    attribute :item
    validates :item, validity: true
  end
  class TestModelAllowNil
    include ActiveAttr::Model
    attribute :item
    validates :item, validity: { allow_nil: true }
  end
  class TestModelDisallowNil
    include ActiveAttr::Model
    attribute :item
    validates :item, validity: { allow_nil: false }
  end


  describe ValidityValidator do

    it 'Item is valid' do
      model = TestModel.new(item: TestItem.new(validity: true))
      expect(model.valid?).to eq(true)
      expect(model.errors.count).to eq(0)
    end

    it 'Item is invalid' do
      model = TestModel.new(item: TestItem.new(validity: false))
      expect(model.valid?).to eq(false)
      expect(model.errors.count).to eq(2)
      expect(model.errors.messages).to eq(item: ['must be valid', 'validity attribute is invalid: is not included in the list'])
    end

    describe 'Allow nil' do

      it 'Is true' do
        expect(TestModelAllowNil.new(item: TestItem.new(validity: true)).valid?).to eq(true)
        expect(TestModelAllowNil.new(item: TestItem.new(validity: false)).valid?).to eq(false)
        expect(TestModelAllowNil.new(item: nil).valid?).to eq(true)
      end

      it 'Is false' do
        expect(TestModelDisallowNil.new(item: TestItem.new(validity: true)).valid?).to eq(true)
        expect(TestModelDisallowNil.new(item: TestItem.new(validity: false)).valid?).to eq(false)
        expect(TestModelDisallowNil.new(item: nil).valid?).to eq(false)
      end

    end

  end

end
