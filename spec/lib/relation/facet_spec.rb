require 'spec_helper'

describe Adpla::Relation do
  before do
    @kittens = read_fixture('kittens.jsonld')
    @faceted = read_fixture('kittens_faceted.jsonld')
    @empty = read_fixture('empty.jsonld')
    @mock_api = double('api')
  end
  describe '#facet' do
	  it "do a single field, single value where" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:q=>'kittens')
	    @mock_api.should_receive(:items).with(:q => 'kittens', :facets => :q).and_return('')
	    test.load
	  end
	  it "do a single field, multiple value where" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:q=>['kittens', 'cats'])
	    @mock_api.should_receive(:items).with(:q => ['kittens','cats'], :facets => :q).and_return('')
	    test.load
	  end
	  it "do merge single field, multiple value wheres" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:q=>'kittens').facet(:q=>'cats')
	    @mock_api.should_receive(:items).with(:q => ['kittens','cats'], :facets => :q).and_return('')
	    test.load
	  end
	  it "do a multiple field, single value where" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:q=>'kittens',:foo=>'bears')
	    @mock_api.should_receive(:items).with(:q => 'kittens', :foo=>'bears', :facets => [:q, :foo]).and_return('')
	    test.load
	  end
	  it "should keep scope distinct from spawned Relations" do
	    test = Adpla::Relation.new(Item, @mock_api).facet(:q=>'kittens')
	    test.where(:q=>'cats')
	    @mock_api.should_receive(:items).with(:q => 'kittens', :facets => :q).and_return('')
	    test.load
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
  end

end