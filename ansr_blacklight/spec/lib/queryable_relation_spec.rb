# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Ansr::Blacklight::Relation do

  class ConfiguredTable < Ansr::Arel::BigTable

  end

  class OtherTable < ConfiguredTable
    def name
      'outside'
    end

  end

  context "a bunch of query stuff", type: :unit do

    before(:each) do
      Object.const_set('QueryTestModel', Class.new(TestModel))
      QueryTestModel.configure do |config|
        config[:table_class] = ConfiguredTable
      end
      QueryTestModel.solr = stub_solr
      other_table.configure_fields do |config|
        hash = (config[:configured] ||= {})
        hash[:local] = {:property => 'test', :escape => 'tes"t'}
      end

    end
    let(:relation) { QueryTestModel.from(ConfiguredTable.new(QueryTestModel)) }
    let(:visitor) { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(QueryTestModel.table) }
    let(:table) { QueryTestModel.table }
    let(:other_table) { OtherTable.new(QueryTestModel) }
    after(:each) do
      @relation = nil
      Object.send(:remove_const, :QueryTestModel)
    end
    describe '#find' do
      subject {QueryTestModel}
      it 'should call where and load with a single value arg' do
        relation = double('Relation')
        allow(relation).to receive(:limit).and_return(relation)
        allow(relation).to receive(:to_a).and_return(['foo'])
        expect(subject).to receive(:where).with('id' =>'lolwut').and_return(relation)
        expect(subject.find('lolwut')).to eql 'foo'
      end
    end
    describe "#from" do
      subject {relation.from(other_table)}

      it "should set the path to the table name" do
        query = visitor.accept subject.build_arel.ast
        expect(query.path).to eql('outside')
      end

      it "should change the table" do
        expect(subject.from_value.first).to be_a ConfiguredTable
      end
    end

    describe "#as" do
      subject {relation.as('hey')}

      it "should set the :qt parameter" do
        query = visitor.accept subject.build_arel.ast
        expect(query.to_hash[:qt]).to eql 'hey'
      end
    end

    describe "#facet" do
      subject { relation.facet(limit: 20)}

      it "should set default facet parms when no field expr is given" do
        query = visitor.accept subject.build_arel.ast
        expect(query.to_hash["facet.limit"]).to eql('20')
      end

      it "should set pivot facet field params" do
      end
    end

    describe '#as' do
      subject { relation.as('hey') }
      it do
        query = visitor.accept subject.build_arel.ast
        expect(query.to_hash["qt"]).to eql('hey')
      end
    end

    context "a mix of queryable relations" do
      subject { relation.from(other_table) }

      it "should accept valid parameters" do
        ## COMMON AREL CONCEPTS ##
        # from() indicates the big table name for the relation; in BL/Solr this maps to the request path 
        # as() indicates an alias for the big table; in BL/Solr this maps to the :qt param
        relation.as!('hey')
        # constraints map directly
        relation.where!(:configured=> "what's")

        # as do offsets and limits
        relation.offset!(21)
        relation.limit!(12)
        relation.group!("I")
        ## COMMON NO-SQL CONCEPTS ##
        # facets are a kind of projection with attributes (attribute support is optional)
        relation.facet!("title_facet", limit: "vest")
        # filters are a type of constraint
        relation.filter!({"name_facet" => "Fedo"})
        relation.facet!("name_facet", limit: 10)
        relation.facet!(limit: 20)
        relation.highlight!("I", 'fl' =>  "wish")
        relation.spellcheck!("a", q: "fleece")
        ## SOLR ECCENTRICITIES ##
        # these are present for compatibility, but not expected to be used generically
        relation.wt!("going")
        relation.defType!("had")
        query = visitor.accept subject.build_arel.ast
        expect(query.path).to eq('outside')
        expect(query.to_hash).to eq({"defType" => "had",
           "f.name_facet.facet.limit" => "10",
           "f.title_facet.facet.limit" => "vest",
           "facet" => true,
           "facet.field" => [:title_facet,:name_facet],
           "facet.limit" => "20",
           "fq" => ["{!term f=name_facet}Fedo"],
           "group" => "I",
           "hl" => "I",
           "hl.fl" => "wish",
           "q" => "{!property=test escape='tes\\\"t'}what\\'s",
           "qt" => "hey",
           "rows" => "12",
           "spellcheck" => "a",
           "spellcheck.q" => "fleece",
           "start" => "21",
           "wt" => "going"
        })
      end
    end  
  end
end
