class CreateAuthors < ActiveRecord::Migration[8.1]
 def change
    create_table :authors do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :authors, :name, unique: true
    add_index :authors, :slug, unique: true
  end
end
