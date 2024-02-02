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

ActiveRecord::Schema[7.0].define(version: 2024_02_01_163223) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "linkedins", force: :cascade do |t|
    t.string "link_job"
    t.string "linkedin_id_job"
    t.string "title"
    t.text "description"
    t.datetime "posted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type_job"
    t.string "location"
    t.index ["linkedin_id_job"], name: "index_linkedins_on_linkedin_id_job"
  end

  create_table "upwork_accounts", force: :cascade do |t|
    t.string "email", null: false
    t.string "password", null: false
    t.string "control_answer"
    t.integer "role"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "upwork_ai", id: false, force: :cascade do |t|
    t.bigint "id"
    t.string "uuid"
    t.string "search_endpoint"
    t.string "title"
    t.string "category"
    t.string "job_location"
    t.string "project_type"
    t.text "description"
    t.string "skills", array: true
    t.string "skill_level"
    t.string "payment_type"
    t.string "payment_value"
    t.string "job_url"
    t.integer "job_proposals"
    t.integer "job_interviews"
    t.integer "job_invites_sent"
    t.string "client_location"
    t.integer "client_job_posted"
    t.integer "client_hire_rate"
    t.string "client_total_spent"
    t.string "client_domain"
    t.string "client_company_size"
    t.string "client_avg_rate"
    t.string "client_paid_hours"
    t.datetime "posted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "upwork_jobs", force: :cascade do |t|
    t.string "uuid"
    t.string "search_endpoint"
    t.string "title"
    t.string "category"
    t.string "job_location"
    t.string "project_type"
    t.text "description"
    t.string "skills", default: [], array: true
    t.string "skill_level"
    t.string "payment_type"
    t.string "payment_value"
    t.string "job_url"
    t.integer "job_proposals"
    t.integer "job_interviews"
    t.integer "job_invites_sent"
    t.string "client_location"
    t.integer "client_job_posted"
    t.integer "client_hire_rate"
    t.string "client_total_spent"
    t.string "client_domain"
    t.string "client_company_size"
    t.string "client_avg_rate"
    t.string "client_paid_hours"
    t.datetime "posted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
