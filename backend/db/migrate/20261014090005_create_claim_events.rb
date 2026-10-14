class CreateClaimEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :claim_events do |t|
      t.references :claim, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :from_status
      t.string :to_status, null: false
      t.text :comment
      t.datetime :created_at, null: false
    end
  end
end
