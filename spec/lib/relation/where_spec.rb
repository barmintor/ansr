require 'spec_helper'

describe Adpla::Relation do
  before do
    @kittens = read_fixture('kittens.jsonld')
    @faceted = read_fixture('kittens_faceted.jsonld')
    @empty = read_fixture('empty.jsonld')
    @mock_api = double('api')
  end
  describe '#where' do
    it "do a single field, single value where" do
      test = Adpla::Relation.new(Item, @mock_api).where(:q=>'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens').and_return('')
      test.load
    end
    it "do a single field, multiple value where" do
      test = Adpla::Relation.new(Item, @mock_api).where(:q=>['kittens', 'cats'])
      @mock_api.should_receive(:items).with(:q => ['kittens','cats']).and_return('')
      test.load
    end
    it "do merge single field, multiple value wheres" do
      test = Adpla::Relation.new(Item, @mock_api).where(:q=>'kittens').where(:q=>'cats')
      @mock_api.should_receive(:items).with(:q => ['kittens','cats']).and_return('')
      test.load
    end
    it "do a multiple field, single value where" do
      test = Adpla::Relation.new(Item, @mock_api).where(:q=>'kittens',:foo=>'bears')
      @mock_api.should_receive(:items).with(:q => 'kittens', :foo=>'bears').and_return('')
      test.load
    end
    it "should keep scope distinct from spawned Relations" do
      test = Adpla::Relation.new(Item, @mock_api).where(:q=>'kittens')
      test.where(:q=>'cats')
      @mock_api.should_receive(:items).with(:q => 'kittens').and_return('')
      test.load
    end
    describe '#not' do
      it 'should exclude a specified map of field values' do
        test = Adpla::Relation.new(Item, @mock_api)
        test = test.where(:foo =>'kittens')
        test = test.where.not(:foo => 'cats')
        @mock_api.should_receive(:items).with(:foo => ['kittens', 'NOT cats']).and_return('')
        test.load
      end

      pending 'should exclude a value from the default query' do
        test = Adpla::Relation.new(Item, @mock_api)
        test = test.where('kittens')
        test = test.where.not('cats')
        @mock_api.should_receive(:items).with(:q => ['kittens', 'NOT cats']).and_return('')
        test.load
      end

      pending 'should exclude a specified field' do
        test = Adpla::Relation.new(Item, @mock_api)
        test = test.where(:foo => 'kittens')
        test = test.where.not('cats')
        @mock_api.should_receive(:items).with(:foo => 'kittens', :q => 'NOT cats').and_return('')
        test.load
      end
    end
    describe '#or' do
      it 'should union a specified map of field values' do
        test = Adpla::Relation.new(Item, @mock_api)
        test = test.where(:foo =>'kittens')
        test = test.where.or(:foo => 'cats')
        @mock_api.should_receive(:items).with(:foo => ['kittens', 'OR cats']).and_return('')
        test.load
      end
    end
  end
end