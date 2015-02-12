require 'spec_helper'

describe Ansr::Dpla::Relation do
  before do
    @kittens = read_fixture('kittens.jsonld')
    @faceted = read_fixture('kittens_faceted.jsonld')
    @empty = read_fixture('empty.jsonld')
    @mock_api = double('api')
    Item.config{ |x| x[:api_key] = :foo}
    Item.engine.api= @mock_api
  end

  subject { Ansr::Dpla::Relation.new(Item, Item.table) }
  describe '#filter' do
    describe "do a single field, single value filter" do
      it "with facet" do
        test = subject.filter(:object=>'kittens').facet(:object)
        @mock_api.should_receive(:items).with(:object => 'kittens', :facets => :object).and_return('')
        test.load
      end
      it "without facet" do
        test = subject.filter(:object=>'kittens')
        @mock_api.should_receive(:items).with(:object => 'kittens').and_return('')
        test.load
      end
    end
    it "do a single field, multiple value filter" do
      test = subject.filter(:object=>['kittens', 'cats']).facet(:object)
      @mock_api.should_receive(:items).with(:object => ['kittens','cats'], :facets => :object).and_return('')
      test.load
    end
    it "do merge single field, multiple value filters" do
      test = subject.filter(:"provider.name"=>'kittens').filter(:"provider.name"=>'cats').facet(:"provider.name")
      @mock_api.should_receive(:items).with(hash_including(:"provider.name" => ['kittens','cats'], :facets => :"provider.name")).and_return('')
      test.load
    end
    it "do a multiple field, single value filter" do
      test = subject.filter(:object=>'kittens',:isShownAt=>'bears').facet([:object, :isShownAt])
      @mock_api.should_receive(:items).with(hash_including(:object => 'kittens', :isShownAt=>'bears', :facets => [:object, :isShownAt])).and_return('')
      test.load
    end
    it "should keep scope distinct from spawned Relations" do
      test = subject.filter(:"provider.name"=>'kittens').facet(:"provider.name")
      test.where(:q=>'cats')
      @mock_api.should_receive(:items).with(:"provider.name" => 'kittens', :facets => :"provider.name").and_return('')
      test.load
    end
    it "should raise an error if the requested field is not a facetable field" do
      expect {subject.facet(:foo)}.to raise_error
    end
    it "should facet without a filter" do
      test = subject.facet(:object)
      @mock_api.should_receive(:items).with(:facets => :object).and_return('')
      test.load
    end
  end

  describe '#filters' do
    it 'should return Blacklight types' do
      # Blacklight::SolrResponse::Facets::FacetItem.new(:value => s, :hits => v)
      # options = {:sort => 'asc', :offset => 0}
      # Blacklight::SolrResponse::Facets::FacetField.new name, items, options
      test = subject.where(:q=>'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens').and_return(@faceted)
      test.load
      fkey = test.facets.keys.first
      facet = test.facets[fkey]
      expect(facet).to be_a(Ansr::Facets::FacetField)
      facet.items
    end
    it 'should dispatch a query with no docs requested if not loaded' do
      test = subject.where(:q=>'kittens')
      @mock_api.should_receive(:items).with(:q => 'kittens', :page_size=>0).once.and_return(@faceted)
      fkey = test.facets.keys.first
      facet = test.facets[fkey]
      expect(facet).to be_a(Ansr::Facets::FacetField)
      expect(test.loaded?).to be_false
      test.facets # make sure we memoized the facet values
    end
  end

end