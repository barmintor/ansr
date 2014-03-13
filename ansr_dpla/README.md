Ansr::Dpla
=====

DPLA + ActiveRecord::Relation + Blacklight

This project creates a Rails model that can be used to search the DPLA's public REST API (http://dp.la/info/developers/codex/).

To use the Item and Collection models, they must first be configured with a DPLA API key:

    Item.config({:api_key => 'your api key'})
Instructions for creating an API key are here: http://dp.la/info/developers/codex/policies/#get-a-key

Once the model is configured, it can be queried like any other Rails model. 

    item_id = "7eb617e559007e1ad6d95bd30a30b16b"
    Item.find(item_id)
    Item.dataProvider # returns a single string value

The Item and Collection models are searched like other Rails models, with relations. To search a single field, call 'where':

    rel = Item.where(q: 'kittens') # full text search for 'kittens'

Where clauses can be negated:

    rel = rel.where.not(q: => 'cats') # maximize cuteness density
Where clauses support simple unions:

    rel = rel.where.or(q: => 'puppies') # so egalitarian
These relations are lazy-loaded; they make no queries until data is required:

    rel.load # loads the data if not loaded
    rel.to_a # loads the data if not loaded, returns an array of model instances
    rel.filters # loads the data if not loaded, returns a list of the filters/facets for the query
    rel.count # returns the number of records loaded

This is to support a decorator pattern on the relations:

    rel = Item.where(q; 'kittens').where.not(q: 'cats')
    rel = rel.limit(25).offset(50) # start on the third page of 25

In addition to where, there are a number of other decorator clauses:

    # select limits the fields returned
    rel = rel.select(:id, :"sourceResource.title")
    # limit sets the maximum number of records to return, default is 10
    rel = rel.limit(25)
    # offset sets a starting point; it must be a multiple of the limit
    rel = rel.offset(50) # start on page 3
    # order adds sort clauses
    rel = rel.order(:"sourceResource.title")
    
When using the filter decorator, you can add field names without a query. This will add the field to the relations filter information after load:

    # filter adds filter/facet clauses
    rel = rel.filter(:"collection.id" => '460c76299e1b0a46afea352b1ab8f556')
    rel = rel.filter(:isShownAt)
    rel.filters # -> a list of two filters, and the counts for the filter constraint values in the response set

 And more, as per ActiveRecord and illustrated in the specs.
