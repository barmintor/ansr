require 'spec_helper'

describe ActiveNoSql::Relation do
  before do
    @kittens = read_fixture('kittens.jsonld')
    @faceted = read_fixture('kittens_faceted.jsonld')
    @empty = read_fixture('empty.jsonld')
    @mock_api = double('api')
    Item.config({:api_key => :foo})
    Item.engine.api= @mock_api
  end

  describe '#select' do
    describe 'with a block given' do
      it "should build an array" do
        test = ActiveNoSql::Relation.new(Item, Item.table).where(q:'kittens')
        @mock_api.should_receive(:items).with(:q => 'kittens').and_return(@kittens)
        actual = test.select {|d| true}
        expect(actual).to be_a(Array)
        expect(actual.length).to eql(test.limit_value)
        actual = test.select {|d| false}
        expect(actual).to be_a(Array)
        expect(actual.length).to eql(0)
      end
    end
    describe 'with a String or Symbol key given' do
      it 'should change the requested document fields' do
        test = ActiveNoSql::Relation.new(Item, Item.table).where(q:'kittens')
        @mock_api.should_receive(:items).with(:q => 'kittens', :fields=>'name').and_return('')
        test = test.select('name')
        test.load
      end
    end
    describe 'with a list of keys' do
      it "should add all the requested document fields" do
        test = ActiveNoSql::Relation.new(Item, Item.table).where(q:'kittens')
        @mock_api.should_receive(:items).with(:q => 'kittens', :fields=>'name,foo').and_return('')
        test = test.select(['name','foo'])
        test.load
      end
      it "should add all the requested document fields and proxy them" do
        test = ActiveNoSql::Relation.new(Item, Item.table).where(q:'kittens')
        @mock_api.should_receive(:items).with(:q => 'kittens', :fields=>'object').and_return(@kittens)
        test = test.select('object AS my_object')
        test.load
        expect(test.to_a.first['object']).to be_nil
        expect(test.to_a.first['my_object']).to eql('http://ark.digitalcommonwealth.org/ark:/50959/6682xj30d/thumbnail')
      end
    end
  end

end