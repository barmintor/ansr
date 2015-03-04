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
    def name
      'outside'
    end

    def [](val)
      key = (Arel::Attributes::Attribute === val) ? val.name.to_sym : val.to_sym
      key == :configured ? Ansr::Arel::ConfiguredField.new(nil, key, {:property => 'test', :escape => 'tes"t'}) : super(val)
    end

    def fields
      [:id]
    end

  end

  before do
    Object.const_set('FacetModel', Class.new(TestModel))
    FacetModel.solr = stub_solr
    FacetModel.configure do |config|
      config[:table_class] = TestTable
    end
  end

  after do
    Object.send(:remove_const, :FacetModel)
  end

  before(:each) do
    @all_docs_query = ''
    @no_docs_query = 'zzzzzzzzzzzz'
    @single_word_query = 'include'
    @mult_word_query = 'tibetan history'
  #  f[format][]=Book&f[language_facet][]=English
    @single_facet = {:format=>'Book'}
    @multi_facets = {:format=>'Book', :language_facet=>'Tibetan'}
    @bad_facet = {:format=>'666'}
    @subject_search_params = {:commit=>"search", :search_field=>"subject", :action=>"index", :"controller"=>"catalog", :"rows"=>"10", :"q"=>"wome"}
    @abc_resp = {'response' =>{ 'docs' => [id: 'abc']}}.to_json
    @no_docs_resp = {'response' =>{'docs' => []}}.to_json
  end

  def subject_search_params(rel)
    rel.limit(10).where!(q: 'wome')
  end
    
  describe "http_method configuration", :integration => true do
    subject { FacetModel }

    it "should send a post request to solr and get a response back" do
      subject.method = :post
      rel = subject.where(:q => @all_docs_query)
      subject.solr= stub_solr(JSON.parse(@abc_resp).inspect)
      expect(rel.length).to be >= 1
    end
  end

  # SPECS for actual search parameter generation
  describe "solr_search_params" do

    subject { FacetModel }

    it "allows customization of solr_search_params_logic" do
        # Normally you'd include a new module into (eg) your CatalogController
        # but a sub-class defininig it directly is simpler for test.             
        subject.stub(:add_foo_to_solr_params) do |rel|
          rel.wt!("TESTING")
        end
                         
        subject.solr_search_params_logic += [:add_foo_to_solr_params]
                
        expect(subject.build_default_scope.wt_value).to eql("TESTING")               
    end

    describe "for an empty string search" do
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(FacetModel.table) }      
      it "should return empty string q in solr parameters" do
        rel = TestModel.where(q: "")
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:q]).to eq ""
        expect(solr_params["spellcheck.q"]).to eq ""
      end
    end

    describe "for request params also passed in as argument" do      
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(FacetModel.table) }      
      it "should only have one value for the key 'q' regardless if a symbol or string" do        
        rel = FacetModel.where(q: "some query").where('q' => 'another value')
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:q]).to eq 'another\ value'
        expect(solr_params['q']).to eq 'another\ value'
      end
    end


    describe "for one facet, no query" do
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(FacetModel.table) }      
      it "should have proper solr parameters" do
        rel = FacetModel.filter(@single_facet)
        solr_params = subject.accept(rel.build_arel.ast)      

        expect(solr_params[:q]).to be_blank
        expect(solr_params["spellcheck.q"]).to be_blank

        @single_facet.each_value do |value|
          expect(solr_params[:fq]).to include("{!term f=#{@single_facet.keys[0]}}#{value}")
        end
      end
    end

    describe "with Multi Facets, No Query" do
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(FacetModel.table) }      
      it 'should have fq set properly' do
        rel = FacetModel.filter(@multi_facets)
        solr_params = subject.accept(rel.build_arel.ast)      

        @multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            expect(solr_params[:fq]).to include("{!term f=#{facet_field}}#{value}"  )
          end
        end

      end
    end

    describe "with Multi Facets, Multi Word Query" do
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(FacetModel.table) }      
      it 'should have fq and q set properly' do
        rel = FacetModel.filter(@multi_facets).where(q: @mult_word_query)
        solr_params = subject.accept(rel.build_arel.ast)      

        @multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            expect(solr_params[:fq]).to include("{!term f=#{facet_field}}#{value}"  )
          end
        end
        expect(solr_params[:q]).to eq RSolr.escape(@mult_word_query)
      end
    end

    describe "filter_value_to_fq_string" do
      let(:table) { FacetModel.table }
      subject { Ansr::Blacklight::Arel::Visitors::QueryBuilder.new(table) }
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

      it "should pass date-type fields through" do
        table.configure_fields do |config|
          config[:facet_name] = {date: true}
        end

        expect(subject.send(:filter_value_to_fq_string, "facet_name", "2012-01-01")).to eq "facet_name:2012\\-01\\-01"
      end

      it "should handle range requests" do
        expect(subject.send(:filter_value_to_fq_string, "facet_name", 1..5)).to eq "facet_name:[1 TO 5]"
      end

      it "should add tag local parameters" do
        table.configure_fields do |config|
          config[:facet_name] = {local: {tag: 'asdf'}}
        end

        expect(subject.send(:filter_value_to_fq_string, "facet_name", true)).to eq "{!tag=asdf}facet_name:true"
        expect(subject.send(:filter_value_to_fq_string, "facet_name", "my value")).to eq "{!term f=facet_name tag=asdf}my value"
      end
    end

    describe "solr parameters for a field search from config (subject)" do
      let(:table) { FacetModel.table }
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(table) }
      let(:rel) { FacetModel.build_default_scope.spawn }
      let(:blacklight_config) { copy_of_catalog_config }
      before do
        table.configure_fields do |config|
          hash = (config[:subject] ||= {local: {}, query: {}})
          hash[:query][:'spellcheck.dictionary'] = 'subject'
          hash[:query][:qt] = 'search'
          hash[:local][:pf] = '$subject_pf'
          hash[:local][:qf] = '$subject_qf'
        end
        rel.where!(subject: 'wome')
      end
      after do
        table.configure_fields { |config| config.clear }
      end
      it "should look up qt from field definition" do
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:qt]).to eq "search"
      end
      it "should not include weird keys not in field definition" do
        solr_params = subject.accept(rel.build_arel.ast)      
        solr_params.to_hash.tap do |h|
          expect(h[:phrase_filters]).to be_nil
          expect(h[:fq]).to be_nil
          expect(h[:commit]).to be_nil
          expect(h[:action]).to be_nil
          expect(h[:controller]).to be_nil
        end
      end
      it "should include proper 'q', possibly with LocalParams" do
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:q]).to match(/(\{[^}]+\})?wome/)
      end
      it "should include proper 'q' when LocalParams are used" do
        solr_params = subject.accept(rel.build_arel.ast)      
        if solr_params[:q] =~ /\{[^}]+\}/
          expect(solr_params[:q]).to match(/\{[^}]+\}wome/)
        end
      end
      it "should include spellcheck.q, without LocalParams" do
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params["spellcheck.q"]).to eq "wome"
      end

      it "should include spellcheck.dictionary from field def solr_parameters" do
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:"spellcheck.dictionary"]).to eq "subject"
      end
      it "should add on :solr_local_parameters using Solr LocalParams style" do
        solr_params = subject.accept(rel.build_arel.ast)      

        #q == "{!pf=$subject_pf $qf=subject_qf} wome", make sure
        #the LocalParams are really there
        solr_params[:q] =~ /^\{!([^}]+)\}/
        key_value_pairs = $1.split(" ")
        expect(key_value_pairs).to include("pf=$subject_pf")
        expect(key_value_pairs).to include("qf=$subject_qf")
      end
    end

    describe "overriding of qt parameter" do
      let(:table) { FacetModel.table }
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(table) }
      let(:rel) { FacetModel.build_default_scope.as('overriden') }
      let(:blacklight_config) { copy_of_catalog_config }
      it "should return the correct overriden parameter" do
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:qt]).to eq "overriden"
      end
    end

    describe "converts a String fq into an Array" do
      let(:table) { FacetModel.table }
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(table) }
      let(:rel) { FacetModel.build_default_scope }
      it "should return the correct overriden parameter" do
        solr_params = subject.accept(rel.facet('a string').build_arel.ast)      
        expect(solr_params[:fq]).to be_a_kind_of Array
      end
    end

    describe "#add_solr_fields_to_query" do
      let(:table) { FacetModel.table }
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(table) }
      let(:rel) { FacetModel.build_default_scope}
      before do
        FacetModel.table.configure_fields do |config|
          config[:an_index_field] = {select: { 'hl.alternativeField' => 'field_x'}}
          config[:a_show_field] = {select: { 'hl.alternativeField' => 'field_y'}}
        end
      end
      after do
        FacetModel.table.configure_fields.clear
      end

      it "should add any extra solr parameters from index and show fields" do
        solr_params = subject.accept(rel.select(:an_index_field, :a_show_field).build_arel.ast)      
        expect(solr_params[:'f.an_index_field.hl.alternativeField']).to eq "field_x"
        expect(solr_params[:'f.a_show_field.hl.alternativeField']).to eq "field_y"
      end
    end

    describe "#add_facetting_to_solr" do

      let(:table) { FacetModel.table }
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(table) }
      let(:rel) {
        FacetModel.build_default_scope.spawn
          .facet('test_field', :sort => 'count')
          .facet('some-query', :query => {'x' => {:fq => 'some:query'}} , :ex => 'xyz')
          .facet('some-pivot', :pivot => ['a','b'], :ex => 'xyz')
          .facet('some-field', mincount: 15 )
      }

      it "should add sort parameters" do
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:facet]).to eql(true)

        expect(solr_params[:'facet.field']).to include(:'test_field')
        expect(solr_params[:'f.test_field.facet.sort']).to eq 'count'
      end

      it "should add facet exclusions" do
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:'facet.query']).to include('{!ex=xyz}some:query')
        expect(solr_params[:'facet.pivot']).to include('{!ex=xyz}a,b')
      end

      it "should add any additional solr_params" do
        solr_params = subject.accept(rel.build_arel.ast)      
        expect(solr_params[:'f.some-field.facet.mincount']).to eq '15'
      end
    end

    describe "for :solr_local_parameters config" do
      let(:table) { FacetModel.table }
      subject { Ansr::Blacklight::Arel::Visitors::ToNoSql.new(table) }
      let(:rel) { FacetModel.build_default_scope.spawn }
      let(:result) { subject.accept rel.where(:custom_author_key => "query").build_arel.ast }
      before do
        table.configure_fields do |config|
          hash = (config[:custom_author_key] ||= {local: {}, query: {}, select: {}})
          hash[:query][:'spellcheck.dictionary'] = 'subject'
          hash[:query][:qt] = 'author_qt'
          hash[:query][:qf] = 'someField^1000'
          hash[:query][:ps] = '2'
          hash[:local][:pf] = "you'll have \" to escape this"
          hash[:local][:pf2] = '$pf2_do_not_escape_or_quote'
          hash[:local][:qf] = '$author_qf'
        end
        rel.where!(subject: 'wome')
      end
      after do
        table.configure_fields { |config| config.clear }
      end
      
      it "should pass through ordinary params" do
        expect(result[:qt]).to eq "author_qt"
        expect(result[:ps]).to eq "2"
        expect(result[:qf]).to eq "someField^1000"
      end

      it "should include include local params with escaping" do
        expect(result[:q]).to include('qf=$author_qf')
        expect(result[:q]).to include('pf=\'you\\\'ll have \\" to escape this\'')
        expect(result[:q]).to include('pf2=$pf2_do_not_escape_or_quote')
      end
    end
  end

  describe "solr_facet_params" do
    before do
      @facet_field = 'format'
      @generated_solr_facet_params = subject.solr_facet_params(@facet_field)

      @sort_key = Blacklight::Solr::FacetPaginator.request_keys[:sort]
      @page_key = Blacklight::Solr::FacetPaginator.request_keys[:page]
    end

    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_fields_to_solr_request!
        config.add_facet_field 'format'
        config.add_facet_field 'format_ordered', :sort => :count
        config.add_facet_field 'format_limited', :limit => 5

      end
    end

    pending 'sets rows to 0' do
      expect(@generated_solr_facet_params[:rows]).to eq 0
    end
    pending 'sets facets requested to facet_field argument' do
      expect(@generated_solr_facet_params["facet.field".to_sym]).to eq @facet_field
    end
    pending 'defaults offset to 0' do
      expect(@generated_solr_facet_params[:"f.#{@facet_field}.facet.offset"]).to eq 0
    end
    pending 'uses offset manually set, and converts it to an integer' do
      solr_params = subject.solr_facet_params(@facet_field, @page_key => 2)
      expect(solr_params[:"f.#{@facet_field}.facet.offset"]).to eq 20
    end
    pending 'defaults limit to 20' do
      solr_params = subject.solr_facet_params(@facet_field)
      expect(solr_params[:"f.#{@facet_field}.facet.limit"]).to eq 21
    end

    describe 'if facet_list_limit is defined in controller' do
      before do
        allow(subject).to receive(:facet_list_limit).and_return(1000)
      end
      pending 'uses controller method for limit' do
        solr_params = subject.solr_facet_params(@facet_field)
        expect(solr_params[:"f.#{@facet_field}.facet.limit"]).to eq 1001
      end

      pending 'uses controller method for limit when a ordinary limit is set' do
        solr_params = subject.solr_facet_params(@facet_field)
        expect(solr_params[:"f.#{@facet_field}.facet.limit"]).to eq 1001
      end
    end

    pending 'uses the default sort' do
      solr_params = subject.solr_facet_params(@facet_field)
      expect(solr_params[:"f.#{@facet_field}.facet.sort"]).to be_blank
    end

    pending "uses the field-specific sort" do
      solr_params = subject.solr_facet_params('format_ordered')
      expect(solr_params[:"f.format_ordered.facet.sort"]).to eq :count
    end

    pending 'uses sort provided in the parameters' do
      solr_params = subject.solr_facet_params(@facet_field, @sort_key => "index")
      expect(solr_params[:"f.#{@facet_field}.facet.sort"]).to eq 'index'
    end
    pending "comes up with the same params as #solr_search_params to constrain context for facet list" do
      search_params = {:q => 'tibetan history', :f=> {:format=>'Book', :language_facet=>'Tibetan'}}
      solr_search_params = subject.solr_search_params( search_params )
      solr_facet_params = subject.solr_facet_params('format', search_params)

      solr_search_params.each_pair do |key, value|
        # The specific params used for fetching the facet list we
        # don't care about.
        next if ['facets', "facet.field", 'rows', 'facet.limit', 'facet.offset', 'facet.sort'].include?(key)
        # Everything else should match
        expect(solr_facet_params[key]).to eq value
      end

    end
  end

end