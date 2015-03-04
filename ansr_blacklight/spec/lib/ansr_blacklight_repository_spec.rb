# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Ansr::Blacklight::Repository do

  let :solr_config do
    c = double('config')
  end
  let :model do
    model = double('Model')
    allow(model).to receive(:name).and_return('Model')
    model
  end
  let :table do
    double('BigTable')
  end
  subject do
    Ansr::Blacklight::Repository.new(model)
  end

  let :mock_response do
    r = Ansr::Blacklight::Relation.new(model, table)
    allow(r).to receive(:load)
    allow(r).to receive(:to_a).and_return([document])
    r
  end

  let :document do
    {}
  end

  describe "#find" do

    it "should use the document-specific solr path" do
      subject.configure do |config|
        config[:document_solr_path] = 'abc'
        config[:solr_path] = 'xyz'
        config[:model] = model
        config[:document_unique_id_param] = :di
      end

      expect(model).to receive(:spawn).and_return(mock_response)
      allow(mock_response).to receive(:from!).with('abc').and_return(mock_response)
      expect(mock_response).to receive(:where!).with(di:'123').and_return(mock_response)
      expect(mock_response).to receive(:load)
      expect(subject.find("123")).to be(mock_response)
    end

    it "should use the default solr path" do
      subject.configure do |config|
        config[:solr_path] = 'xyz'
        config[:model] = model
        config[:document_unique_id_param] = :di
      end

      expect(model).to receive(:spawn).and_return(mock_response)
      allow(mock_response).to receive(:from!).with('xyz').and_return(mock_response)
      expect(mock_response).to receive(:where!).with(di:'123').and_return(mock_response)
      expect(mock_response).to receive(:load)
      expect(subject.find("123")).to be(mock_response)
    end

    it "should use a default :qt param" do
      subject.configure do |config|
        config[:model] = model
        config[:document_solr_request_handler] = 'abc'
        config[:document_unique_id_param] = :di
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:as!).with('abc').and_return(mock_response)
      allow(mock_response).to receive(:from!).with('xyz').and_return(mock_response)
      expect(mock_response).to receive(:where!).with(di:'123').and_return(mock_response)
      expect(mock_response).to receive(:load)
      expect(subject.find("123")).to be(mock_response)
    end

    it "should use the provided :qt param" do
      subject.configure do |config|
        config[:model] = model
        config[:document_solr_request_handler] = 'abc'
        config[:document_unique_id_param] = :di
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:as!).with('abc').and_return(mock_response)
      allow(mock_response).to receive(:from!).with('xyz').and_return(mock_response)
      expect(mock_response).to receive(:where!).with(di:'123').and_return(mock_response)
      expect(mock_response).to receive(:load)
      expect(subject.find("123", {qt: 'abc'})).to be(mock_response)
    end

    pending "should preserve the class of the incoming params" do
      subject.configure do |config|
        config[:model] = model
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:where!).with(id:'123').and_return(mock_response)
      response = subject.find("123", HashWithIndifferentAccess.new)
      expect(response).to be_a_kind_of Ansr::Blacklight::Relation
      expect(response.values).to be_a_kind_of HashWithIndifferentAccess
    end
  end

  describe "#search" do
    it "should use the search-specific solr path" do
      subject.configure do |config|
        config[:model] = model
        config[:solr_path] = 'xyz'
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:from!).with('xyz').and_return(mock_response)
      expect(mock_response).to receive(:load)
      response = subject.search({})
      expect(response).to be_a_kind_of Ansr::Blacklight::Relation
    end

    it "should use the default solr path" do
      subject.configure do |config|
        config[:model] = model
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:load)
      response = subject.search({})
      expect(response).to be_a_kind_of Ansr::Blacklight::Relation
    end

    it "should use a default :qt param" do
      subject.configure do |config|
        config[:model] = model
        config[:document_solr_request_handler] = 'xyz'
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:as!).with('xyz').and_return(mock_response)
      expect(mock_response).to receive(:load)
      response = subject.search({})
      expect(response).to be_a_kind_of Ansr::Blacklight::Relation
    end

    it "should use the provided :qt param" do
      subject.configure do |config|
        config[:model] = model
        config[:document_solr_request_handler] = 'xyz'
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:as!).with('abc').and_return(mock_response)
      expect(mock_response).to receive(:load)
      response = subject.search({qt: 'abc'})
      expect(response).to be_a_kind_of Ansr::Blacklight::Relation
    end
    
    pending "should preserve the class of the incoming params" do
      search_params = HashWithIndifferentAccess.new
      search_params[:q] = "query"
      allow(subject.blacklight_solr).to receive(:send_and_receive).with('select', anything).and_return(mock_response)
      
      response = subject.search(search_params)
      expect(response).to be_a_kind_of Blacklight::SolrResponse
      expect(response.values).to be_a_kind_of HashWithIndifferentAccess
    end
  end

end