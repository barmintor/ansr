require 'spec_helper'

describe Ansr::Dpla::Api do

  describe '#config' do
    before do
      @test = Ansr::Dpla::Api.new
    end

    it "should be configurable with a Hash" do
      config_fixture = {:api_key => :foo, :url => :bar}
      @test.config(config_fixture)
      expect(@test.url).to eql(:bar)
    end

    it "should be configurable with a path to a yaml" do
      @test.config(fixture_path('dpla.yml'))
      expect(@test.url).to eql('http://fake.dp.la/v0/')
    end

    it "should raise an error of the config doesn't have required fields" do
      expect { Ansr::Dpla::Api.new.config({:url => :foo})}.to raise_error
      Ansr::Dpla::Api.new.config({:url => :foo, :api_key => :foo})
    end

  end

  describe '#path_for' do
    before do
      @test = Ansr::Dpla::Api.new
      @test.config({:api_key => :testing})
    end


    describe 'queries' do
      it "should build paths for basic queries" do
        fixture = {:foo => ['kittens', 'cats'], :bar => ['puppies', 'dogs']}
        expected = 'tests?api_key=testing&foo=kittens+AND+cats&bar=puppies+AND+dogs'
        expect(@test.path_for('tests', fixture)).to eql(expected)
        expect(@test.items_path(fixture)).to eql(expected.sub(/^tests/,'items'))
        expect(@test.collections_path(fixture)).to eql(expected.sub(/^tests/,'collections'))
        expect(@test.item_path('foo')).to eql('items/foo?api_key=testing')
        expect(@test.collection_path('foo')).to eql('collections/foo?api_key=testing')
      end

      it "should build paths for OR and NOT queries" do
        fixture = {:foo => ['kittens', 'NOT cats']}
        expected = 'tests?api_key=testing&foo=kittens+AND+NOT+cats'
        expect(@test.path_for('tests', fixture)).to eql(expected)

        fixture = {:foo => ['NOT kittens', 'cats']}
        expected = 'tests?api_key=testing&foo=NOT+kittens+AND+cats'
        expect(@test.path_for('tests', fixture)).to eql(expected)

        fixture = {:foo => ['kittens', 'OR cats']}
        expected = 'tests?api_key=testing&foo=kittens+OR+cats'
        expect(@test.path_for('tests', fixture)).to eql(expected)

        fixture = {:foo => ['OR kittens', 'cats']} 
        expected = 'tests?api_key=testing&foo=kittens+AND+cats'
        expect(@test.path_for('tests', fixture)).to eql(expected)
      end
    end

    it "should build paths for facets right" do
      fixture = {:foo => 'kittens', :facets => :bar}
      expected = 'tests?api_key=testing&foo=kittens&facets=bar'
      expect(@test.path_for('tests', fixture)).to eql(expected)

      fixture = {:foo => 'kittens', :facets => [:bar, :baz]}
      expected = 'tests?api_key=testing&foo=kittens&facets=bar%2Cbaz'
      expect(@test.path_for('tests', fixture)).to eql(expected)

      fixture = {:foo => 'kittens', :facets => 'bar,baz'}
      expected = 'tests?api_key=testing&foo=kittens&facets=bar%2Cbaz'
      expect(@test.path_for('tests', fixture)).to eql(expected)
    end

    it "should build paths for sorts right" do
      fixture = {:foo => 'kittens', :sort_by => [:bar, :baz]}
      expected = 'tests?api_key=testing&foo=kittens&sort_by=bar%2Cbaz'
      expect(@test.path_for('tests', fixture)).to eql(expected)

      fixture = {:foo => 'kittens', :sort_by => 'bar,baz'}
      expected = 'tests?api_key=testing&foo=kittens&sort_by=bar%2Cbaz'
      expect(@test.path_for('tests', fixture)).to eql(expected)

      fixture = {:foo => 'kittens', :sort_by => 'bar,baz', :sort_order => :desc}
      expected = 'tests?api_key=testing&foo=kittens&sort_by=bar%2Cbaz&sort_order=desc'
      expect(@test.path_for('tests', fixture)).to eql(expected)
    end

    it "should build paths for field selections right" do
      fixture = {:foo => 'kittens', :fields => [:bar, :baz]}
      expected = 'tests?api_key=testing&foo=kittens&fields=bar%2Cbaz'
      expect(@test.path_for('tests', fixture)).to eql(expected)

      fixture = {:foo => 'kittens', :fields => 'bar,baz'}
      expected = 'tests?api_key=testing&foo=kittens&fields=bar%2Cbaz'
      expect(@test.path_for('tests', fixture)).to eql(expected)
    end

    it "should build paths for limits and page sizes right" do
      fixture = {:foo => 'kittens', :page_size=>25, :page=>4}
      expected = 'tests?api_key=testing&foo=kittens&page_size=25&page=4'
      expect(@test.path_for('tests', fixture)).to eql(expected)
    end

  end
end
