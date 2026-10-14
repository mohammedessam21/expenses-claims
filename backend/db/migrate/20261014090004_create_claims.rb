class CreateClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :claims do |t|
      t.string :reference_code, null: false
      t.references :company, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: { to_table: :users }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.string :status, null: false
      t.integer :amount_halalas, null: false
      t.integer :limit_halalas_at_submission, null: false
      t.text :description, null: false
      t.date :spent_on, null: false
      t.timestamps
    end
    add_index :claims, :reference_code, unique: true
    add_index :claims, [:company_id, :status]
  end
end
