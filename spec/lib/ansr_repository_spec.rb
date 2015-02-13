require 'spec_helper'

describe Ansr::Repository do

  let :model do
    model = double('Model')
    allow(model).to receive(:name).and_return('Model')
    model
  end
  let :engine do
    engine = double('Engine')
    allow(engine).to receive(:engine).and_return(engine)
  end
  let :table do
    table = double('BigTable')
    engine =
    allow(table).to receive(:engine).and_return(engine)
  end
  subject do
    Ansr::Repository.new(model)
  end

  let :mock_response do
    r = Ansr::Relation.new(model, table)
    allow(r).to receive(:load)
    allow(r).to receive(:to_a).and_return([document])
    r
  end

  let :document do
    {id:'123'}
  end

  describe "#find" do

    it "should use the configured id field key" do
      subject.configure do |config|
        config[:model] = model
        config[:document_unique_id_param] = :di
      end

      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:where!).with(di:'123').and_return(mock_response)
      expect(mock_response).to receive(:as).with('lol').and_return(mock_response)
      expect(mock_response).to receive(:load).and_return([document])
      actual = subject.find("123", as: 'lol') {|r,c,p| r = r.as(p[:as]); r}
      expect(actual).to be(mock_response)
    end
    it "should call a block on query if passed"
    pending "should preserve the class of the incoming params" do
      subject.configure do |config|
        config[:model] = model
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:where!).with(id:'123').and_return(mock_response)
      response = subject.find("123", HashWithIndifferentAccess.new)
      expect(response).to be_a_kind_of Ansr::Relation
      expect(response.values).to be_a_kind_of HashWithIndifferentAccess
    end
  end

  describe "#search" do
    it "should call spawn and load" do
      subject.configure do |config|
        config[:model] = model
      end
      expect(model).to receive(:spawn).and_return(mock_response)
      expect(mock_response).to receive(:load)
      response = subject.search({})
      expect(response).to be_a_kind_of Ansr::Relation
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