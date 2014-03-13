ansr
====

ActiveRecord(No-SQL)::Relation + Blacklight

Ansr is a library for building ActiveRecord-style models and Relation implementations that query no-SQL data sources.
Ansr is motivated by a proposed refactoring of Blacklight at Code4Lib 2014.

[Blacklight](https://github.com/projectblacklight/blacklight) (BL) defines itself as “an open source Solr user interface discovery platform.” The coupling to Solr is evident in the structure: Solr querying facilities are sprinkled throughout several mixins that are included in BL controllers. This results in a codebase that cannot, as is regularly asked on the mailing lists, be used in front of another document store (eg ElasticSeach).  But this is not necessarily the case.

BL might be refactored to locate the actual Solr querying machinery behind the core model of BL apps (currently called SolrDocument).  Refactoring the codebase this way would realize several benefits:

1.   Adherence to the Principle of Least Surprise: The BL document model would behave more like a Rails model backed by RDBMS. When bringing new developers into a BL project, familiarity with the standard patterns of Rails would translate more immediately to the BL context.

2.   Flexible abstraction of the document store: Moving the specifics of querying the document store would make the introduction of models interacting with other stores possible. For example, the DPLA REST API exposes some Solr-like concepts, and a proof-of-concept model for an ActiveRecord-like approach to searching them can be seen at (https://github.com/barmintor/ansr/ansr_adpla)

3.   Clearer testing strategies and ease of console debugging

4.   Clarification of BL’s relationship to RSolr as the provider to an analog for ActiveRecord::Relation

What would such a refactor require?

1.   A definition of the backend requirements of BL beyond a reference to Solr per se: indexed documents with fields, a concept of facets corresponding to the Solr/Lucene definitions, the ability to expose Hash-like representations of results.

2.   A relocation of the searching methods from Blacklight::Catalog and Blacklight::SolrHelper into a model generated to include Solr code

3.   An accommodation of controller-specific Solr configuration, possibly resolved by having the BL config register Solr parms with the model a la SolrDocument extensions in BL 4

4.   An abstraction of the fielded/faceted search parameters to mimic ActiveRecord limits

5.   A partner institution capable of producing integration and system testing support for, at minimum, another Lucene-backed document store (ElasticSearch)

Since these changes are incompatible with current BL, they are proposed as a principal feature of BL 6.0.

An example of the kinds of models to be implemented can be seen in a [DPLA proof of concept](https://github.com/barmintor/ansr/ansr_adpla).
