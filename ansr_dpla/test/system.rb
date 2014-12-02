$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app/models'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'ansr_dpla'
require 'item'

# you config the model with a hash including an API key for dp.la/v2, or the path to a YAML file
open('config/dpla.yml') do |blob|
  Item.config {|x| x.merge! YAML.load(blob)}
end

# then you can find single items with known IDs
puts Item.find("7eb617e559007e1ad6d95bd30a30b16b")


# or you can search with ActiveRecord::Relations
opts = {q: 'kittens', facets: 'sourceResource.contributor'}
rel = Item.where(opts)
# this means the results are lazy-loaded, #load or #to_a will load them
rel.to_a
# you can also assemble the queries piecemeal with the Relation's decorator pattern
# the where decorator adds query fields
# the select decorator adds response fields
# the limit decorator adds a page size limit
# the offset decorator adds a non-zero starting point in the response set
# the filter decorator adds filter/facet fields and optionally values to query them on
rel = Item.where(q: 'kittens').limit(2).facet('sourceResource.contributor').select('sourceResource.title')
rel.to_a.each do |item|
  puts "#{item["id"]} \"#{item['sourceResource.title']}\""
end
# the filter values for the query are available on the relation after it is loaded
rel.facets.each do |k,f|
  puts "#{k} values"
  f.items.each do |item|
    puts "facet:  \"#{item.value}\" : #{item.hits}"
  end
end
# the loaded Relation has attributes describing the response set
rel.count # the size of the response
# the where decorator can be negated
rel = rel.where.not(q: 'cats')

rel.to_a.each do |item|
  puts "#{item["id"]} \"#{item['sourceResource.title']}\" \"#{item['originalRecord']}\""
end

rel.facets.each do |k,f|
  puts "#{k} values"
  f.items.each do |item|
    puts "  \"#{item.value}\" : #{item.hits}"
  end
end