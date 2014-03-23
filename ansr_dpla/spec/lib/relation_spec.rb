require 'spec_helper'

describe Ansr::Dpla::Relation do
  before do
    @kittens = read_fixture('kittens.jsonld')
    @faceted = read_fixture('kittens_faceted.jsonld')
    @empty = read_fixture('empty.jsonld')
    @mock_api = double('api')
    Item.config({:api_key => :foo})
    Item.engine.api= @mock_api
  end

  subject { Ansr::Dpla::Relation.new(Item, Item.table) }

  describe "#initialize" do
    it "should identify the correct resource for the model" do
      class Foo
        def self.table
          nil
        end
      end

      test = Ansr::Dpla::Relation.new(Foo, Foo.table)
      expect(test.resource).to eql(:foos)
    end
  end

  describe ".load" do
    it "should fetch the appropriate REST resource" do
      test = subject.where(:q=>'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens').and_return('')
      test.load
    end

    describe "Relation attributes" do
      it "should set attributes correctly from a response" do
        test = subject.where(:q=>'kittens')
        @mock_api.stub(:items).and_return(@kittens)
        test.load
        expect(test.count).to eql(144)
        expect(test.offset_value).to eql(0)
        expect(test.limit_value).to eql(10)
      end

      it "should set attributes correctly for an empty response" do
        test = subject.where(:q=>'kittens')
        @mock_api.stub(:items).and_return(@empty)
        test.load
        expect(test.count).to eql(0)
        expect(test.offset_value).to eql(0)
        expect(test.limit_value).to eql(10)
      end
    end
  end

  describe '#all' do
    it 'should fail because we don\'t have a test yet'
  end

  describe '#none' do
    it 'should fail because we don\'t have a test yet'
  end

  describe '.order' do
    describe 'with symbol parms' do
      it "should add sort clause to query" do
        test = subject.where(:q=>'kittens').order(:foo)
        expect(test).to be_a(Ansr::Relation)
        @mock_api.should_receive(:items).with(:q => 'kittens',:sort_by=>:foo).and_return('')
        test.load
      end

      it "should add multiple sort clauses to query" do
        test = subject.where(:q=>'kittens').order(:foo).order(:bar)
        expect(test).to be_a(Ansr::Relation)
        @mock_api.should_receive(:items).with(:q => 'kittens',:sort_by=>[:foo,:bar]).and_return('')
        test.load
      end

      it "should sort in descending order if necessary" do
        test = subject.where(:q=>'kittens').order(:foo => :desc)
        expect(test).to be_a(Ansr::Relation)
        @mock_api.should_receive(:items).with(:q => 'kittens',:sort_by=>:foo, :sort_order=>:desc).and_return('')
        test.load
      end
    end
    describe 'with String parms' do
      it "should add sort clause to query" do
        test = subject.where(q:'kittens').order("foo")
        expect(test).to be_a(Ansr::Relation)
        @mock_api.should_receive(:items).with(:q => 'kittens',:sort_by=>:foo).and_return('')
        test.load
      end

      it "should sort in descending order if necessary" do
        test = subject.where(q:'kittens').order("foo DESC")
        expect(test).to be_a(Ansr::Relation)
        @mock_api.should_receive(:items).with(:q => 'kittens',:sort_by=>:foo, :sort_order=>:desc).and_return('')
        test.load
      end
    end
  end

  describe '#reorder' do
    it "should replace existing order" do
      test = subject.where(q:'kittens').order("foo DESC")
      test = test.reorder("foo ASC")
      expect(test).to be_a(Ansr::Relation)
      @mock_api.should_receive(:items).with(:q => 'kittens',:sort_by=>:foo).and_return('')
      test.load
    end
  end

  describe '#reverse_order' do
    it "should replace existing DESC order" do
      test = subject.where(q:'kittens').order("foo DESC")
      test = test.reverse_order
      expect(test).to be_a(Ansr::Relation)
      @mock_api.should_receive(:items).with(:q => 'kittens',:sort_by=>:foo).and_return('')
      test.load
    end

    it "should replace existing ASC order" do
      test = subject.where(q:'kittens').order("foo ASC")
      test = test.reverse_order
      expect(test).to be_a(Ansr::Relation)
      @mock_api.should_receive(:items).with(:q => 'kittens',:sort_by=>:foo, :sort_order=>:desc).and_return('')
      test.load
    end
  end

  describe '#unscope' do
    it 'should remove clauses only from spawned Relation' do
      test = subject.where(q:'kittens').order("foo DESC")
      test2 = test.unscope(:order)
      expect(test2).to be_a(Ansr::Relation)
      @mock_api.should_receive(:items).with(:q => 'kittens').and_return('')
      test2.load
      expect(test.order_values.empty?).to be_false
    end
    # ActiveRecord::QueryMethods.VALID_UNSCOPING_VALUES =>
    # Set.new([:where, :select, :group, :order, :lock, :limit, :offset, :joins, :includes, :from, :readonly, :having])
    it 'should reject bad scope keys' do
      test = subject.where(q:'kittens').order("foo DESC")
      expect { test.unscope(:foo) }.to raise_error
    end
  end

  describe '#select' do
    describe 'with a block given' do
      it "should build an array" do
        test = subject.where(q:'kittens')
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
        test = subject.where(q:'kittens')
        @mock_api.should_receive(:items).with(:q => 'kittens', :fields=>:name).and_return('')
        test = test.select('name')
        test.load
      end
    end
    describe 'with a list of keys' do
      it "should add all the requested document fields" do
        test = subject.where(q:'kittens')
        @mock_api.should_receive(:items).with(:q => 'kittens', :fields=>[:name,:foo]).and_return('')
        test = test.select(['name','foo'])
        test.load
      end
      it "should add all the requested document fields and proxy them" do
        test = subject.where(q:'kittens')
        @mock_api.should_receive(:items).with(:q => 'kittens', :fields=>:object).and_return(@kittens)
        test = test.select('object AS my_object')
        test.load
        expect(test.to_a.first['object']).to be_nil
        expect(test.to_a.first['my_object']).to eql('http://ark.digitalcommonwealth.org/ark:/50959/6682xj30d/thumbnail')
      end
    end
  end

  describe '#limit' do
    it "should add page_size to the query params" do
      test = subject.where(q:'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens', :page_size=>17).and_return('')
      test = test.limit(17)
      test.load
    end
    it "should raise an error if limit > 500" do
      test = subject.where(q:'kittens')
      test = test.limit(500)
      expect {test.load }.to raise_error
    end
  end

  describe '#offset' do
    it "should add page to the query params when page_size is defaulted" do
      test = subject.where(q:'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens', :page=>3).and_return('')
      test = test.offset(20)
      test.load
    end
    it 'should raise an error if an offset is requested that is not a multiple of the page size' do
      test = subject.where(q:'kittens').limit(12)
      expect{test.offset(17)}.to raise_error(/^Bad/)
      test.offset(24)
    end
  end

  describe '#to_a' do
    it 'should load the records and return them' do
    end
  end

  describe '#loaded?' do
    it 'should be false before and true after' do
      test = subject.where(q:'kittens')
      @mock_api.stub(:items).with(:q => 'kittens').and_return('')
      expect(test.loaded?).to be_false
      test.load
      expect(test.loaded?).to be_true
    end
  end


  describe '#any?'


  describe '#blank?' do
    it 'should load the records via to_a'

  end

  describe '#count' do
  end

  describe '#empty?' do
    it 'should not make another call if records are loaded' do
      test = subject.where(q:'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens').once.and_return(@empty)
      test.load
      expect(test.loaded?).to be_true
      expect(test.empty?).to be_true
    end

  end

  describe "#spawn" do
    it "should create new, independent Relations from Query methods"

  end

  describe 'RDBMS-specific methods' do
    describe '#references' do
      it 'should not do anything at all'
    end
    describe '#joins' do
      it 'should not do anything at all'
    end
    describe '#distinct and #uniq' do
      it 'should not do anything at all'
    end
    describe '#preload' do
      it 'should not do anything at all'
    end
    describe '#includes' do
      it 'should not do anything at all'
    end
    describe '#having' do
      it 'should not do anything at all'
    end
  end

  describe 'read-write methods' do
    describe '#readonly' do
      it "should blissfully ignore no-args or true"

      it "should refuse values of false"

    end
    describe '#create_with' do
      it 'should not do anything at all'
    end
    describe '#insert' do
      it 'should not do anything at all'
    end
    describe '#delete' do
      it 'should not do anything at all'
    end
    describe '#delete_all' do
      it 'should not do anything at all'
    end
    describe '#destroy' do
      it 'should not do anything at all'
    end
    describe '#destroy_all' do
      it 'should not do anything at all'
    end
  end

end