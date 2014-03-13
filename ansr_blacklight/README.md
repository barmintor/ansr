Ansr::Blacklight
=================

A re-implementation of Blacklight's Solr model with find/search functionality moved behind ActiveRecord::Relation subclasses.

QUESTIONS

Is a closer conformation to the expectations from ActiveRecord valuable enough to forego use of Sunspot (https://github.com/sunspot/sunspot)?

REQUEST REQUIREMENTS

Considering the following block from the BL Solr request code:
  SINGULAR_KEYS = %W{ facet fl q qt rows start spellcheck spellcheck.q sort 
  per_page wt hl group defType}
  ARRAY_KEYS = %W{facet.field facet.query facet.pivot fq hl.fl }

facet : a boolean field indicating the requested presence of facet info in response
fl : the selected fields
q : the query (fielding?)
qt : query type; indicates queryHandler in Solr
rows : corresponds to limit
start : corresponds to offset
spellcheck : boolean?
spellcheck.q : ?
sort : ?
facet.field : the fields for which facet info is requested
facet.query : ?
facet.pivot : ?
fq : ?
hl.fl : field to highlight
How is facet query different from filter query (fq)?

Relations must be configurable with default parameters; this is fairly easy to do with a template Relation to spawn the default scope from.

RESPONSE REQUIREMENTS

tbd
