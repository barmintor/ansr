# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Ansr::Blacklight::RequestBuilders do
  class RequestBuildersTestClass
    attr_accessor :table
    include Ansr::Blacklight::RequestBuilders
  end
  subject { RequestBuildersTestClass.new }
  let(:relation) { double('Relation')}
  before(:each) do
    subject.table = {'facet_name' => Ansr::Arel::ConfiguredField.new(relation, 'facet_name',:date => nil, :query => nil, :tag => nil)}
  end
  describe "filter_value_to_fq_string" do

    it "should use the raw term handler for strings" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", "my value")).to eq "{!term f=facet_name}my value" 
    end

    it "should pass booleans through" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", true)).to eq "facet_name:true"
    end

    it "should pass boolean-like strings through" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", "true")).to eq "facet_name:true"
    end

    it "should pass integers through" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", 1)).to eq "facet_name:1"
    end

    it "should pass integer-like strings through" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", "1")).to eq "facet_name:1"
    end

    it "should pass floats through" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", 1.11)).to eq "facet_name:1\\.11"
    end

    it "should pass floats through" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", "1.11")).to eq "facet_name:1\\.11"
    end

    it "should escape negative integers" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", -1)).to eq "facet_name:\\-1"
    end

    it "should pass date-type fields through" do
      subject.table = {'facet_name' => Ansr::Arel::ConfiguredField.new(relation, 'facet_name',:date => true, :query => nil, :tag => nil)}

      expect(subject.send(:filter_value_to_fq_string, "facet_name", "2012-01-01")).to eq "facet_name:2012\\-01\\-01"
    end

    it "should escape datetime-type fields" do
      subject.table['facet_name'] = Ansr::Arel::ConfiguredField.new(relation, 'facet_name',:date => true, :query => nil, :tag => nil)

      expect(subject.send(:filter_value_to_fq_string, "facet_name", "2003-04-09T00:00:00Z")).to eq "facet_name:2003\\-04\\-09T00\\:00\\:00Z"
    end
    
    it "should format Date objects correctly" do
      subject.table['facet_name'] = Ansr::Arel::ConfiguredField.new(relation, 'facet_name',:date => nil, :query => nil, :tag => nil)
      d = DateTime.parse("2003-04-09T00:00:00")
      expect(subject.send(:filter_value_to_fq_string, "facet_name", d)).to eq "facet_name:2003\\-04\\-09T00\\:00\\:00Z"      
    end

    it "should handle range requests" do
      expect(subject.send(:filter_value_to_fq_string, "facet_name", 1..5)).to eq "facet_name:[1 TO 5]"
    end

    it "should add tag local parameters" do
      subject.table['facet_name'] = Ansr::Arel::ConfiguredField.new(relation, 'facet_name',:date => nil, :query => nil, :tag => 'asdf')

      expect(subject.send(:filter_value_to_fq_string, "facet_name", true)).to eq "{!tag=asdf}facet_name:true"
      expect(subject.send(:filter_value_to_fq_string, "facet_name", "my value")).to eq "{!term f=facet_name tag=asdf}my value"
    end

    describe "#with_tag_ex" do
      it "should add an !ex local parameter if the facet configuration requests it" do
        expect(subject.with_ex_local_param("xyz", "some-value")).to eq "{!ex=xyz}some-value"
      end

      it "should not add an !ex local parameter if it isn't configured" do
        mock_field = double()
        expect(subject.with_ex_local_param(nil, "some-value")).to eq "some-value"
      end
    end

  end
end