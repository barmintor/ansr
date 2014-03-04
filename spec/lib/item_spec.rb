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
      mock_api.should_receive(:item).with('123').and_return(read_fixture('item.jsonld'))
      Item.find('123')
    end
    it "should raise an exception for a bad id" do
      mock_api = double('api')
      Item.api = mock_api
      mock_api.should_receive(:item).with('123').and_return(read_fixture('empty.jsonld'))
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
end