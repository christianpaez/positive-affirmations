# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require 'csv'

def key(s) = s.to_s.strip.downcase
def slug_for(s) = s.to_s.parameterize.presence

author_names = {}
cat_names    = {}
quote_rows   = []

puts "Reading CSV file..."

CSV.foreach('db/seeds/quotes.csv', headers: true) do |row|
  raw_author = row['author']&.strip
  author = raw_author&.split(',')&.first&.strip
   author_slug = slug_for(author)
  if author_slug.nil?
    puts "Skipping (no slug): #{author.inspect}"
    next
  end

  body   = row['quote']&.strip
  next unless author && body

  author_names[key(author)] ||= author
  cats = (row['category'] || '').split(',').map(&:strip).reject(&:empty?)
  cats.each { |c| cat_names[key(c)] ||= c.titleize }
  quote_rows << { body: body, author_key: key(author), category_keys: cats.map { |c| key(c) } }
end

puts "Inserting records..."

ActiveRecord::Base.transaction do
  puts "Inserting Authors..."
  author_names.each_value do |name|
    Author.find_or_create_by!(slug: slug_for(name)) { |a| a.name = name }
  end

  puts "Inserting Categories..."
  cat_names.each_value do |name|
    Category.find_or_create_by!(slug: slug_for(name)) { |c| c.name = name }
  end

  author_ids   = Author.pluck(:name, :id).to_h { |n, id| [ key(n), id ] }
  category_ids = Category.pluck(:name, :id).to_h { |n, id| [ key(n), id ] }

  puts "Inserting quotes..."
  quote_id_by_body = {}
  quote_rows.each do |q|
    aid = author_ids[q[:author_key]]
    raise "No author id for #{q[:author_key]}" if aid.nil?
    quote = Quote.create!(body: q[:body], author_id: aid)
    quote_id_by_body[q[:body]] = quote.id
  end

  qc_data = []
  quote_rows.each do |q|
    qid = quote_id_by_body[q[:body]]
    q[:category_keys].each do |ck|
      cid = category_ids[ck]
      next if cid.nil?
      qc_data << { quote_id: qid, category_id: cid, created_at: Time.current, updated_at: Time.current }
    end
  end

  raise "No QC rows built!" if qc_data.empty?
  puts "Inserting #{qc_data.size} quote/category associations..."
  QuoteCategory.insert_all(qc_data)
end

puts "Done! #{Quote.count} quotes, #{Author.count} authors, #{Category.count} categories, #{QuoteCategory.count} associations."
