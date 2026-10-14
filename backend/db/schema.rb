# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_14_090005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name_en", null: false
    t.string "name_ar", null: false
    t.integer "limit_halalas", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_categories_on_company_id"
  end

  create_table "claim_events", force: :cascade do |t|
    t.bigint "claim_id", null: false
    t.bigint "actor_id", null: false
    t.string "action", null: false
    t.string "from_status"
    t.string "to_status", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.index ["actor_id"], name: "index_claim_events_on_actor_id"
    t.index ["claim_id"], name: "index_claim_events_on_claim_id"
  end

  create_table "claims", force: :cascade do |t|
    t.string "reference_code", null: false
    t.bigint "company_id", null: false
    t.bigint "category_id", null: false
    t.bigint "employee_id", null: false
    t.bigint "reviewer_id"
    t.string "status", null: false
    t.integer "amount_halalas", null: false
    t.integer "limit_halalas_at_submission", null: false
    t.text "description", null: false
    t.date "spent_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_claims_on_category_id"
    t.index ["company_id", "status"], name: "index_claims_on_company_id_and_status"
    t.index ["company_id"], name: "index_claims_on_company_id"
    t.index ["employee_id"], name: "index_claims_on_employee_id"
    t.index ["reference_code"], name: "index_claims_on_reference_code", unique: true
    t.index ["reviewer_id"], name: "index_claims_on_reviewer_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "categories", "companies"
  add_foreign_key "claim_events", "claims"
  add_foreign_key "claim_events", "users", column: "actor_id"
  add_foreign_key "claims", "categories"
  add_foreign_key "claims", "companies"
  add_foreign_key "claims", "users", column: "employee_id"
  add_foreign_key "claims", "users", column: "reviewer_id"
  add_foreign_key "users", "companies"
end
