class CreateQuoteCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_categories do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :quote_categories, [ :quote_id, :category_id ], unique: true
  end
end
