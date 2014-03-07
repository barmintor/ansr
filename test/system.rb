$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app/models'))
require 'adpla'
require 'item'

Item.config('config/dpla.yml')

puts Item.find("7eb617e559007e1ad6d95bd30a30b16b")

opts = {q: 'kittens', facets: 'sourceResource.contributor'}
# what blows up when we pass the facets and fields in as args?
puts Item.api.items_path(opts)
rel = Item.where(opts)
rel.to_a
rel = Item.where(q: 'kittens').limit(2).filter('sourceResource.contributor') #.select('sourceResource.title').select('object.originalRecord')
rel.to_a.each do |item|
  puts "#{item["id"]} \"#{item['sourceResource.title']}\" \"#{item['originalRecord']}\""
end

rel.filters.each do |k,f|
  puts "#{k} values"
  f.items.each do |item|
    puts "filter:  \"#{item.value}\" : #{item.hits}"
  end
end

rel = rel.where.not(q: 'cats')

rel.to_a.each do |item|
  puts "#{item["id"]} \"#{item['sourceResource.title']}\" \"#{item['originalRecord']}\""
end

rel.filters.each do |k,f|
  puts "#{k} values"
  f.items.each do |item|
    puts "  \"#{item.value}\" : #{item.hits}"
  end
end