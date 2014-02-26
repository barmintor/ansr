require 'spec_helper'

describe Adpla::Relation do
  before do
    @kittens = read_fixture('kittens.jsonld')
    @faceted = read_fixture('kittens_faceted.jsonld')
    @empty = read_fixture('empty.jsonld')
    @mock_api = double('api')
  end
  describe '#facet' do
	  it "do a single field, single value facet" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:object=>'kittens')
	    @mock_api.should_receive(:items).with(:object => 'kittens', :facets => :object).and_return('')
	    test.load
	  end
	  it "do a single field, multiple value facet" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:object=>['kittens', 'cats'])
	    @mock_api.should_receive(:items).with(:object => ['kittens','cats'], :facets => :object).and_return('')
	    test.load
	  end
	  it "do merge single field, multiple value facets" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:"provider.name"=>'kittens').facet(:"provider.name"=>'cats')
	    @mock_api.should_receive(:items).with(:"provider.name" => ['kittens','cats'], :facets => :"provider.name").and_return('')
	    test.load
	  end
	  it "do a multiple field, single value facet" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:object=>'kittens',:isShownAt=>'bears')
	    @mock_api.should_receive(:items).with(:object => 'kittens', :isShownAt=>'bears', :facets => [:object, :isShownAt]).and_return('')
	    test.load
	  end
	  it "should keep scope distinct from spawned Relations" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:"provider.name"=>'kittens')
	    test.where(:q=>'cats')
	    @mock_api.should_receive(:items).with(:"provider.name" => 'kittens', :facets => :"provider.name").and_return('')
	    test.load
	  end
	  it "should raise an error if the requested field is not a faceted field" do
	    test = Adpla::Relation.new(Item, @mock_api)
	    expect {test.facet(:foo=>'kittens')}.to raise_error
	  end
  end

  describe '#facets' do
    it 'should return Blacklight types' do
      # Blacklight::SolrResponse::Facets::FacetItem.new(:value => s, :hits => v)
      # options = {:sort => 'asc', :offset => 0}
      # Blacklight::SolrResponse::Facets::FacetField.new name, items, options
      test = Adpla::Relation.new(Item, @mock_api).where(:q=>'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens').and_return(@faceted)
      test.load
      fkey = test.facets.keys.first
      facet = test.facets[fkey]
      expect(facet).to be_a(Blacklight::SolrResponse::Facets::FacetField)
      facet.items
    end
    it 'should dispatch a query with no docs requested if not loaded' do
      test = Adpla::Relation.new(Item, @mock_api).where(:q=>'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens', :page_size=>0).once.and_return(@faceted)
      fkey = test.facets.keys.first
      facet = test.facets[fkey]
      expect(facet).to be_a(Blacklight::SolrResponse::Facets::FacetField)
      expect(test.loaded?).to be_false
      test.facets # make sure we memoized the facet values
    end
  end

end