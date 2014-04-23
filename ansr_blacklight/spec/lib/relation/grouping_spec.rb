# -*- encoding : utf-8 -*-
require 'spec_helper'

# check the methods that do solr requests. Note that we are not testing if
#  solr gives "correct" responses, as that's out of scope (it's a part of
#  testing the solr code itself).  We *are* testing if blacklight code sends
#  queries to solr such that it gets appropriate results. When a user does a search,
#  do we get data back from solr (i.e. did we properly configure blacklight code
#  to talk with solr and get results)? when we do a document request, does
#  blacklight code get a single document returned?)
#
describe Ansr::Blacklight do

  class TestTable < Ansr::Arel::BigTable

    def [](val)
      key = (Arel::Attributes::Attribute === val) ? val.name.to_sym : val.to_sym
      key == :configured ? Ansr::Arel::ConfiguredField.new(key, {:property => 'test', :escape => 'tes"t'}) : super(val)
    end

    def fields
      [:id]
    end

  end

  before do
    Object.const_set('GroupModel', Class.new(TestModel))
    GroupModel.solr = stub_solr(sample_response)
    GroupModel.configure do |config|
      config[:table_class] = TestTable
    end
  end

  after do
    Object.send(:remove_const, :GroupModel)
  end

  let(:response) do
    create_response(sample_response)
  end

  let(:group) do
    response.grouped(GroupModel).select { |x| x.key == "result_group_ssi" }.first
  end

  subject do
    group.groups.first
  end

  describe Ansr::Blacklight::Solr::Response::Group do
    describe "#doclist" do
      it "should be the raw list of documents from solr" do
        expect(subject.doclist).to be_a Hash
        expect(subject.doclist['docs'].first[:id]).to eq 1
      end
    end

    describe "#total" do
      it "should be the number of results found in a group" do
        expect(subject.total).to eq 2
      end
    end

    describe "#start" do
      it "should be the offset for the results in the group" do
        expect(subject.start).to eq 0
      end
    end

    describe "#docs" do
      it "should be a list of GroupModels" do
        subject.docs.each do |doc|
          expect(doc).to be_a_kind_of GroupModel
        end
      
        expect(subject.docs.first.id).to eq 1
      end
    end

    describe "#field" do
      it "should be the field the group belongs to" do
        expect(subject.field).to eq "result_group_ssi"
      end
    end
  end

  describe Ansr::Blacklight::Solr::Response do
    let(:response) do
      create_response(sample_response)
    end

    let(:group) do
      response.grouped(GroupModel).select { |x| x.key == "result_group_ssi" }.first
    end

    describe "groups" do
      it "should return an array of Groups" do
        response.grouped(GroupModel).should be_a Array

        expect(group.groups).to have(2).items
        group.groups.each do |group|
          expect(group).to be_a Ansr::Blacklight::Solr::Response::Group
        end
      end
      it "should include a list of SolrDocuments" do

        group.groups.each do |group|
          group.docs.each do |doc|
            expect(doc).to be_a GroupModel
          end
        end
      end
    end
    
    describe "total" do
      it "should return the ngroups value" do
        expect(group.total).to eq 3
      end
    end
    
    describe "facets" do
      it "should exist in the response object (not testing, we just extend the module)" do
        expect(group).to respond_to :facets
      end
    end
    
    describe "rows" do
      it "should get the rows from the response" do
        expect(group.rows).to eq 3
      end
    end

    describe "group_field" do
      it "should be the field name for the current group" do
        expect(group.group_field).to eq "result_group_ssi"
      end
    end

    describe "group_limit" do
      it "should be the number of documents to return for a group" do
        expect(group.group_limit).to eq 5
      end
    end
  end

  def sample_response
    {"responseHeader" => {"params" =>{"rows" => 3, "group.limit" => 5}},
     "grouped" => 
       {'result_group_ssi' => 
         {'groups' => [{'groupValue'=>"Group 1", 'doclist'=>{'numFound'=>2, 'start' => 0, 'docs'=>[{:id=>1}, {:id => 'x'}]}},
                       {'groupValue'=>"Group 2", 'doclist'=>{'numFound'=>3, 'docs'=>[{:id=>2}, :id=>3]}}
                      ],
          'ngroups' => "3"
         }
       }
    }
  end
end