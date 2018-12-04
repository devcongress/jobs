# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_12_02_105418) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clients", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_clients_on_company_id"
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.text "name", null: false
    t.text "industry", null: false
    t.text "logo", default: "", null: false
    t.text "website", default: "", null: false
    t.text "description", null: false
    t.text "email", null: false
    t.text "phone", null: false
    t.text "city", null: false
    t.text "state_or_region", null: false
    t.text "post_code", null: false
    t.text "country", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_companies_on_email", unique: true
  end

  create_table "industries", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower(name)", name: "lower_industry_name", unique: true
  end

  create_table "jobs", force: :cascade do |t|
    t.string "role", null: false
    t.string "duration"
    t.string "salary", null: false
    t.string "requirements", null: false
    t.string "qualification", null: false
    t.string "perks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.boolean "remote_ok", default: true, null: false
    t.bigint "company_id", null: false
    t.string "city", default: "", null: false
    t.string "country", default: "", null: false
    t.text "apply_link", default: "", null: false
    t.datetime "filled_at"
    t.index ["company_id"], name: "index_jobs_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "clients", "companies"
  add_foreign_key "clients", "users"
  add_foreign_key "jobs", "companies"
end
