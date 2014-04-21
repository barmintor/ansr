require 'spec_helper'

describe Ansr::Blacklight::Relation do
  def stub_solr
    @solr ||= double('Solr')
    @solr.stub(:send_and_receive).and_return('')
    @solr
  end

  class TestModel < Ansr::Blacklight::Base
    def self.solr=(solr)
      @solr = solr
    end
    def self.solr
      @solr
    end
  end

  class TestTable < Ansr::Arel::BigTable
    def name
      'outside'
    end

    def [](val)
      key = (Arel::Attributes::Attribute === val) ? val.name.to_sym : val.to_sym
      key == :configured ? Ansr::Arel::ConfiguredField.new(key, {:property => 'test', :escape => 'tes"t'}) : super(val)
    end
  end

  before do
    TestModel.solr = stub_solr
    #TestModel.blacklight_config.facet_fields[:name_facet] = :foo
    @relation = Ansr::Blacklight::Relation.new(TestModel, TestModel.table)
  end

  after do
    @relation = nil
  end

  subject { @relation }

  let(:r) { subject }
  let(:visitor) {Ansr::Blacklight::Arel::Visitors::ToNoSql.new(TestModel.table)}
  describe "a bunch of query stuff" do
    before do
      ## COMMON AREL CONCEPTS ##
      # from() indicates the big table name for the relation; in BL/Solr this maps to the request path 
      subject.from!(TestTable.new(TestModel))
      # as() indicates an alias for the big table; in BL/Solr this maps to the :qt param
      subject.as!('hey')
      # constraints map directly
      subject.where!(:configured=> "what's")

      # as do offsets and limits
      subject.offset!(21)
      subject.limit!(12)
      subject.group!("I")
      ## COMMON NO-SQL CONCEPTS ##
      # facets are a kind of projection with attributes (attribute support is optional)
      subject.facet!("title_facet", limit: "vest")
      # filters are a type of constraint
      subject.filter!({"name_facet" => "Fedo"})
      subject.facet!("name_facet", limit: 10)
      subject.facet!(limit: 20)
      subject.highlight!("I", 'fl' =>  "wish")
      subject.spellcheck!("a", q: "fleece")
      ## SOLR ECCENTRICITIES ##
      # these are present for compatibility, but not expected to be used generically
      subject.wt!("going")
      subject.defType!("had")
    end

    describe "#from" do
      subject {@relation.from(TestTable.new(TestModel))}
      it "should set the path to the table name"
        query = visitor.accept subject.build_arel.ast
        expect(query.path).to eql('outside')
      end

      it "should change the table" do
        expect(subject.table).to be_a TestTable
      end
    end

    describe "#as" do
      subject {@relation.as('hey')}
      it "should set the :qt parameter" do
        query = visitor.accept subject.build_arel.ast
        expect(query.to_hash[:qt]).to eql 'hey'
      end
    end

    describe "#facet" do
      subject { @relation.facet(limit: 20)}
      it "should set default facet parms when no field expr is given" do
        rel = subject.facet(limit: 20)
        query = visitor.accept rel.
      end
      it "should set facet field params" do
      end
    end

    it "should accept valid parameters" do
      config = Blacklight::Configuration.new
      query = visitor.accept subject.build_arel.ast
      expect(query.path).to eq('outside')
      expect(query.to_hash).to eq({"defType" => "had",
         "f.name_facet.facet.limit" => "10",
         "f.title_facet.facet.limit" => "vest",
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
