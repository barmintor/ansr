require 'spec_helper'

describe Ansr::Relation do
  before do
    @kittens = read_fixture('kittens.jsonld')
    @faceted = read_fixture('kittens_faceted.jsonld')
    @empty = read_fixture('empty.jsonld')
    @mock_api = double('api')
    Item.config({:api_key => :foo})
    Item.engine.api= @mock_api
  end
  describe '#filter' do
	  it "do a single field, single value filter" do
	    test = Ansr::Relation.new(Item, Item.table).filter(:object=>'kittens')
	    @mock_api.should_receive(:items).with(:object => 'kittens', :facets => :object).and_return('')
	    test.load
	  end
	  it "do a single field, multiple value filter" do
	    test = Ansr::Relation.new(Item, Item.table).filter(:object=>['kittens', 'cats'])
	    @mock_api.should_receive(:items).with(:object => ['kittens','cats'], :facets => :object).and_return('')
	    test.load
	  end
	  it "do merge single field, multiple value filters" do
	    test = Ansr::Relation.new(Item, Item.table).filter(:"provider.name"=>'kittens').filter(:"provider.name"=>'cats')
	    @mock_api.should_receive(:items).with(:"provider.name" => ['kittens','cats'], :facets => :"provider.name").and_return('')
	    test.load
	  end
	  it "do a multiple field, single value filter" do
	    test = Ansr::Relation.new(Item, Item.table).filter(:object=>'kittens',:isShownAt=>'bears')
	    @mock_api.should_receive(:items).with(:object => 'kittens', :isShownAt=>'bears', :facets => [:object, :isShownAt]).and_return('')
	    test.load
	  end
	  it "should keep scope distinct from spawned Relations" do
	    test = Ansr::Relation.new(Item, Item.table).filter(:"provider.name"=>'kittens')
	    test.where(:q=>'cats')
	    @mock_api.should_receive(:items).with(:"provider.name" => 'kittens', :facets => :"provider.name").and_return('')
	    test.load
	  end
	  it "should raise an error if the requested field is not a filtered field" do
	    test = Ansr::Relation.new(Item, Item.table)
	    expect {test.filter(:foo=>'kittens')}.to raise_error
	  end
    it "should not require a search value for the filter" do
      test = Ansr::Relation.new(Item, Item.table).filter(:object)
      @mock_api.should_receive(:items).with(:facets => :object).and_return('')
      test.load
    end
  end

  describe '#filters' do
    it 'should return Blacklight types' do
      # Blacklight::SolrResponse::Facets::FacetItem.new(:value => s, :hits => v)
      # options = {:sort => 'asc', :offset => 0}
      # Blacklight::SolrResponse::Facets::FacetField.new name, items, options
      test = Ansr::Relation.new(Item, Item.table).where(:q=>'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens').and_return(@faceted)
      test.load
      fkey = test.filters.keys.first
      facet = test.filters[fkey]
      expect(facet).to be_a(Blacklight::SolrResponse::Facets::FacetField)
      facet.items
    end
    it 'should dispatch a query with no docs requested if not loaded' do
      test = Ansr::Relation.new(Item, Item.table).where(:q=>'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens', :page_size=>0).once.and_return(@faceted)
      fkey = test.filters.keys.first
      facet = test.filters[fkey]
      expect(facet).to be_a(Blacklight::SolrResponse::Facets::FacetField)
      expect(test.loaded?).to be_false
      test.filters # make sure we memoized the facet values
    end
  end

end