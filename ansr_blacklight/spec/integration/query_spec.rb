# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Ansr::Blacklight::Base do

  before do
    Object.const_set('QueryTestTable', Class.new(Ansr::Arel::BigTable))
    Object.const_set('QueryTestModel', Class.new(Ansr::Blacklight::Base))
    QueryTestModel.configure do |config|
      config[:table_class] = QueryTestTable
      config[:unique_key] = 'id'
    end
  end

  after do
    Object.send(:remove_const, :QueryTestModel) if Object.const_defined? :QueryTestModel
    Object.send(:remove_const, :QueryTestTable) if Object.const_defined? :QueryTestTable
  end
  describe '#find' do
    describe 'with a single id value specified' do
      it do
        doc = QueryTestModel.find('8675309')
        expect(doc['id']).to eql('8675309')
        expect(doc['release_dtsi']).to eql('1981-11-16T00:00:00Z')
      end
    end
  end
  describe '#where' do
    describe 'with a single fielded query value specified' do
      it do
        rel = QueryTestModel.where('lyrics_tesim' => 'number')
        rel.load
        doc = rel.to_a.first
        expect(doc['id']).to eql('8675309')
        expect(doc['release_dtsi']).to eql('1981-11-16T00:00:00Z')
      end
    end
  end
  describe '#filter' do
    describe 'with a single fielded query value specified' do
      it do
        rel = QueryTestModel.filter('release_dtsi' => '1981-11-16T00:00:00Z')
        rel.load
        doc = rel.to_a.first
        expect(doc['id']).to eql('8675309')
        expect(doc['release_dtsi']).to eql('1981-11-16T00:00:00Z')
      end
    end
  end
end