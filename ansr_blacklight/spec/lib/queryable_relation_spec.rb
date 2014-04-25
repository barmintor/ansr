require 'spec_helper'

describe Ansr::Blacklight::Relation do

  class ConfiguredTable < Ansr::Arel::BigTable

  end

  class OtherTable < ConfiguredTable
    def name
      'outside'
    end

  end

  context "a bunch of query stuff" do

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
      @visitor = Ansr::Blacklight::Arel::Visitors::ToNoSql.new(QueryTestModel.table)

      ## COMMON AREL CONCEPTS ##
      # from() indicates the big table name for the relation; in BL/Solr this maps to the request path 
      @relation = QueryTestModel.from(ConfiguredTable.new(QueryTestModel))
      # as() indicates an alias for the big table; in BL/Solr this maps to the :qt param
      @relation.as!('hey')
      # constraints map directly
      @relation.where!(:configured=> "what's")

      # as do offsets and limits
      @relation.offset!(21)
      @relation.limit!(12)
      @relation.group!("I")
      ## COMMON NO-SQL CONCEPTS ##
      # facets are a kind of projection with attributes (attribute support is optional)
      @relation.facet!("title_facet", limit: "vest")
      # filters are a type of constraint
      @relation.filter!({"name_facet" => "Fedo"})
      @relation.facet!("name_facet", limit: 10)
      @relation.facet!(limit: 20)
      @relation.highlight!("I", 'fl' =>  "wish")
      @relation.spellcheck!("a", q: "fleece")
      ## SOLR ECCENTRICITIES ##
      # these are present for compatibility, but not expected to be used generically
      @relation.wt!("going")
      @relation.defType!("had")
    end

    after(:each) do
      @relation = nil
      Object.send(:remove_const, :QueryTestModel)
    end

    let(:table) { QueryTestModel.table }
    let(:other_table) { OtherTable.new(QueryTestModel) }
    describe "#from" do

      let(:visitor) { @visitor }
      subject {@relation.from(other_table)}

      it "should set the path to the table name" do
        query = visitor.accept subject.build_arel.ast
        expect(query.path).to eql('outside')
      end

      it "should change the table" do
        expect(subject.from_value.first).to be_a ConfiguredTable
      end
    end

    describe "#as" do

      subject {@relation.as('hey')}
      let(:visitor) { @visitor }

      it "should set the :qt parameter" do
        query = visitor.accept subject.build_arel.ast
        expect(query.to_hash[:qt]).to eql 'hey'
      end
    end

    describe "#facet" do

      subject { @relation.facet(limit: 20)}
      let(:visitor) { @visitor }

      it "should set default facet parms when no field expr is given" do
        rel = subject.facet(limit: 20)
        query = visitor.accept rel.build_arel.ast
      end

      it "should set facet field params" do
      end
    end

    context "a mix of queryable relations" do
      subject { @relation.from(other_table) }
      let(:visitor) { @visitor }

      it "should accept valid parameters" do
        query = visitor.accept subject.build_arel.ast
        expect(query.path).to eq('outside')
        expect(query.to_hash).to eq({"defType" => "had",
           "f.name_facet.facet.limit" => "10",
           "f.title_facet.facet.limit" => "vest",
           "facet" => true,
           "facet.field" => [:title_facet,:name_facet],
           "facet.limit" => "20",
           "fq" => ["{!raw f=name_facet}Fedo"],
           "group" => "I",
           "hl" => "I",
           "hl.fl" => "wish",
           "q" => "{!property=test escape='tes\\\"t'}what's",
           "qt" => "hey",
           "rows" => "13",
           "spellcheck" => "a",
           "spellcheck.q" => "fleece",
           "start" => "21",
           "wt" => "going"
        })
      end
    end  
  end
end
