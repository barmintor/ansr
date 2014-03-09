require 'spec_helper'

describe Item do
  describe '.configure' do
    it "should store the configured Api class" do
    	Item.configure({:api=>Adpla::TestApi, :api_key => :dummy})
    	expect(Item.api).to be_a Adpla::TestApi
    end
  end

  describe '.find' do
    it "should find an item given an id" do
      mock_api = double('api')
      Item.api = mock_api
      mock_api.should_receive(:items).with(:id=>"123", :page_size=>1).and_return(read_fixture('item.jsonld'))
      Item.find('123')
    end
    it "should raise an exception for a bad id" do
      mock_api = double('api')
      Item.api = mock_api
      mock_api.should_receive(:items).with(:id=>"123", :page_size=>1).and_return(read_fixture('empty.jsonld'))
      expect {Item.find('123')}.to raise_error
    end
  end

  describe '.where' do
  	before do
    	Item.configure({:api=>Adpla::TestApi, :api_key => :dummy})
    end
  	it 'should return a Relation when there is query information' do
      expect(Item.where({:q=>'kittens'})).to be_a ActiveNoSql::Relation
  	end
    it 'should return itself when there is no query information' do
      expect(Item.where({})).to be Item
    end
  end

  describe 'accessor methods' do
    before do
      mock_api = double('api')
      Item.api = mock_api
      @hash = JSON.parse(read_fixture('item.jsonld'))['docs'][0]
      @test = Item.new(@hash)
    end

    it 'should dispatch method names to the hash' do
      @test.dataProvider.should == "Boston Public Library"
      @test.sourceResource.identifier.should == [ "Local accession: 08_06_000884" ]
    end

    it 'should miss methods for undefined fields' do
      expect {@test.foo}.to raise_error
    end
  end


end