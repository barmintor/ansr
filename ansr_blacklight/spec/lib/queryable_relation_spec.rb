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

  before do
    TestModel.solr = stub_solr
    TestModel.blacklight_config.facet_fields[:name_facet] = :foo
    @relation = Ansr::Blacklight::Relation.new(TestModel, TestModel.table)
  end

  after do
    @relation = nil
  end

  subject { @relation }

  let(:r) { subject }
  describe "a bunch of query stuff" do
    before do
      # The filter node will be either Filter(:attrs) or Equality(:left: Filter, :right: Expr)
      subject.facet!("title_facet", limit: "vest")
      subject.filter!({"name_facet" => "Fedo"})
      subject.facet!("name_facet", limit: 10)
      subject.as!('hey') # qt is essentially a table alias; solr path is a table name cf. Relation.from
      subject.where!('q'=> "what's")
      subject.offset!(21)
      subject.limit!(12)
      subject.highlight!("I", 'fl' =>  "wish")
      subject.group!("I")
      subject.spellcheck!("a", q: "fleece")
      subject.wt!("going")
      subject.defType!("had")
    end

    it "should accept valid parameters" do
      config = Blacklight::Configuration.new
      visitor = Ansr::Blacklight::Arel::Visitors::ToNoSql.new(TestModel.table, config)
      query = visitor.accept subject.build_arel.ast
      expect(query.to_hash).to eq({"defType" => "had",
         "f.name_facet.facet.limit" => "10",
         "f.title_facet.facet.limit" => "vest",
         "facet.field" => [:title_facet,:name_facet],
         "fq" => ["{!raw f=name_facet}Fedo"],
         "group" => "I",
         "hl" => "I",
         "hl.fl" => "wish",
         "q" => "what's",
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
