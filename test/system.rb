$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app/models'))
require 'adpla'
require 'item'

Item.config('config/dpla.yml')
opts = {q: 'kittens', facets: 'sourceResource.contributor', fields: 'sourceResource.title'}
# what blows up when we pass the facets and fields in as args?
puts Item.api.items_path(opts)
rel = Item.where(opts)
rel.to_a
rel = Item.where(q: 'kittens').limit(2).facet('sourceResource.contributor').select('sourceResource.title')
rel.to_a.each do |item|
  puts "#{item.__id__} \"#{item['sourceResource.title']}\""
end

rel.facets.each do |k,f|
  puts "#{k} values"
  f.items.each do |item|
    puts "  \"#{item.value}\" : #{item.hits}"
  end
end

rel = rel.where.not(q: 'cats')

rel.to_a.each do |item|
  puts "#{item.__id__} \"#{item['sourceResource.title']}\""
end

rel.facets.each do |k,f|
  puts "#{k} values"
  f.items.each do |item|
    puts "  \"#{item.value}\" : #{item.hits}"
  end
end