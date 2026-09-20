require 'csv'

def slug_for(s) = s.to_s.parameterize.presence

def progress(label, current, total)
  print "\r#{label}: #{current}/#{total}"
  $stdout.flush
end

author_names = {}
cat_names    = {}
quote_rows   = []
CATEGORY_RE = /\A[a-z0-9-]+(,\s*[a-z0-9-]+)*\z/
counts = Hash.new(0)

puts "Reading CSV file..."

File.delete('db/seeds/quotes_rejected.csv') if File.exist?('db/seeds/quotes_rejected.csv')

total_rows = `wc -l < db/seeds/quotes.csv`.to_i - 1
puts "Total rows: #{total_rows}"

CSV.foreach('db/seeds/quotes.csv', headers: true) do |row|
  counts[:rows_read] += 1
  progress("Read", counts[:rows_read], total_rows) if (counts[:rows_read] % 1000).zero?

  if row['quote'].nil? || row['author'].nil? || row['category'].nil?
    counts[:rejected_nil] += 1
    File.open('db/seeds/quotes_rejected.csv', 'a') { |f| f.puts row.to_csv }
    next
  end

  unless row['category'].match?(CATEGORY_RE)
    counts[:rejected_category] += 1
    File.open('db/seeds/quotes_rejected.csv', 'a') { |f| f.puts row.to_csv }
    next
  end

  raw_author = row['author'].strip
  if raw_author.match?(/\A[a-z0-9-]+\z/) || raw_author.length > 40
    counts[:rejected_slug] += 1
    File.open('db/seeds/quotes_rejected.csv', 'a') { |f| f.puts row.to_csv }
    next
  end

  author = raw_author.split(',').first&.strip
  author_slug = slug_for(author)
  if author_slug.nil?
    counts[:rejected_slug] += 1
    File.open('db/seeds/quotes_rejected.csv', 'a') { |f| f.puts row.to_csv }
    next
  end

  body = row['quote'].strip
  if body.empty?
    counts[:rejected_missing] += 1
    File.open('db/seeds/quotes_rejected.csv', 'a') { |f| f.puts row.to_csv }
    next
  end

  counts[:rows_kept] += 1
  author_names[author_slug] ||= author
  cats = row['category'].split(',').map(&:strip).reject(&:empty?)
  cats.each { |c| cat_names[slug_for(c)] ||= c.titleize }
  quote_rows << { body: body, author_slug: author_slug, category_slugs: cats.map { |c| slug_for(c) }.compact }
end

print "\r"
puts "Read:     #{counts[:rows_read]}"
puts "  kept:     #{counts[:rows_kept]}"
puts "  nil:      #{counts[:rejected_nil]}"
puts "  category: #{counts[:rejected_category]}"
puts "  slug:     #{counts[:rejected_slug]}"
puts "  other:    #{counts[:rejected_missing]}"
puts "  rejected: #{counts[:rows_read] - counts[:rows_kept]}"
puts

puts "Inserting records..."

now = Time.current

# --- AUTHORS ---
author_rows = author_names
              .map { |slug, name| { name: name, slug: slug, created_at: now, updated_at: now } }
              .uniq { |r| r[:name] }
puts "Inserting #{author_rows.size} authors..."
author_rows.each_slice(1000).with_index do |chunk, i|
  Author.insert_all(chunk, unique_by: :slug)
  progress("Authors", [ (i + 1) * 1000, author_rows.size ].min, author_rows.size)
end
print "\r"
author_ids = Author.pluck(:slug, :id).to_h
puts "Authors: #{author_ids.size} in DB"

# --- CATEGORIES ---
cat_rows = cat_names
           .map { |slug, name| { name: name, slug: slug, created_at: now, updated_at: now } }
           .uniq { |r| r[:name] }
puts "Inserting #{cat_rows.size} categories..."
cat_rows.each_slice(1000).with_index do |chunk, i|
  Category.insert_all(chunk, unique_by: :slug)
  progress("Categories", [ (i + 1) * 1000, cat_rows.size ].min, cat_rows.size)
end
print "\r"
category_ids = Category.pluck(:slug, :id).to_h
puts "Categories: #{category_ids.size} in DB"

# --- QUOTES ---
puts "Inserting #{quote_rows.size} quotes..."
quote_rows.each_slice(1000).with_index do |chunk, i|
  rows = chunk.filter_map do |q|
    aid = author_ids[q[:author_slug]]
    next if aid.nil?
    { body: q[:body], author_id: aid, created_at: now, updated_at: now }
  end
  Quote.insert_all(rows) unless rows.empty?
  progress("Quotes", [ (i + 1) * 1000, quote_rows.size ].min, quote_rows.size)
end
print "\r"
puts "Quotes: #{Quote.count} in DB"

# --- LOOKUP QUOTE IDS ---
puts "Looking up quote ids..."
quote_id_by_body_author = Quote.pluck(:body, :author_id, :id).to_h { |b, a, id| [ [ b, a ], id ] }

# --- ASSOCIATIONS ---
puts "Building associations..."
qc_data = []
quote_rows.each_with_index do |q, i|
  progress("Associations", i + 1, quote_rows.size) if (i % 1000).zero?

  aid = author_ids[q[:author_slug]]
  qid = quote_id_by_body_author[[ q[:body], aid ]]
  next if qid.nil?

  q[:category_slugs].each do |cslug|
    cid = category_ids[cslug]
    next if cid.nil?
    qc_data << { quote_id: qid, category_id: cid, created_at: now, updated_at: now }
  end
end
print "\r"
puts "Associations built: #{qc_data.size}"

qc_data.each_slice(1000).with_index do |chunk, i|
  QuoteCategory.insert_all(chunk)
  progress("Associations", [ (i + 1) * 1000, qc_data.size ].min, qc_data.size)
end
print "\r"
puts "Associations: #{QuoteCategory.count} in DB"

puts
puts "Done!"
puts "  quotes:       #{Quote.count}"
puts "  authors:      #{Author.count}"
puts "  categories:   #{Category.count}"
puts "  associations: #{QuoteCategory.count}"
