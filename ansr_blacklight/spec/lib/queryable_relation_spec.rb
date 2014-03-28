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
      subject.filter!("title_facet", limit: "vest", select: false)
      subject.filter!({"name_facet" => "Fedo"}, limit: 10, select: false)
      subject.as!('hey') # qt is essentially a table alias; solr path is a table name cf. Relation.from
      subject.where!(:fq => ["what's up.", "dood"])
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
         "f.title_facet.facet.limit" => "vest",
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
