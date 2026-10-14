class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name_en, null: false
      t.string :name_ar, null: false
      t.integer :limit_halalas, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
