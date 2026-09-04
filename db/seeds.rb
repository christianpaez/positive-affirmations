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

author_names = {}
cat_names = {}
quote_rows = []

puts "Starting massive seeds..."

# TODO fix this: SQLite3::ConstraintException: NOT NULL constraint failed: quotes.author_id (SQLite3::ConstraintException)
CSV.foreach('db/seeds/quotes.csv', headers: true) do |row|
  author = row['author']&.strip
  body = row['quote']&.strip
  next unless author && body

  author_names[author] = true
  cats = row['category']&.split(',')&.map(&:strip)&.compact || []
  cats.each { |c| cat_names[c] = true }
  quote_rows << { body: body, author: author, categories: cats }
end

puts "CSV file parsed..."

ActiveRecord::Base.transaction do
  puts "Inserting Authors..."
  Author.insert_all(author_names.keys.map { |n| { name: n, slug: n.parameterize, created_at: Time.current, updated_at: Time.current } })

  puts "Inserting Categories..."
  Category.insert_all(cat_names.keys.map { |n| { name: n.titleize, slug: n.parameterize, created_at: Time.current, updated_at: Time.current } })

  author_ids = Author.pluck(:name, :id).to_h
  category_ids = Category.pluck(:name, :id).to_h

  quotes_data = quote_rows.map do |q|
    { body: q[:body], author_id: author_ids[q[:author]], created_at: Time.current, updated_at: Time.current }
  end

  puts "Inserting quotes..."
  Quote.insert_all(quotes_data)

  quote_ids = Quote.pluck(:body, :id).to_h

  qc_data = []
  quote_rows.each do |q|
    qid = quote_ids[q[:body]]
    q[:categories].each do |cat|
      cid = category_ids[cat]
      qc_data << { quote_id: qid, category_id: cid, created_at: Time.current, updated_at: Time.current } if qid && cid
    end
  end

  puts "Inserting quote/category associations..."
  QuoteCategory.insert_all(qc_data)
end

puts "Done! #{Quote.count} quotes, #{Author.count} authors, #{Category.count} categories."
