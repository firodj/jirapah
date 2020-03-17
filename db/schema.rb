# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_17_031327) do

  create_table "change_logs", force: :cascade do |t|
    t.string "guid"
    t.integer "story_id"
    t.integer "author_id"
    t.text "description"
    t.datetime "created_at"
    t.index ["author_id"], name: "index_change_logs_on_author_id"
    t.index ["guid"], name: "index_change_logs_on_guid", unique: true
    t.index ["story_id"], name: "index_change_logs_on_story_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "guid"
    t.string "name"
    t.index ["guid"], name: "index_members_on_guid", unique: true
  end

  create_table "stories", force: :cascade do |t|
    t.string "guid"
    t.string "key"
    t.text "summary"
    t.string "epic_link"
    t.integer "reporter_id"
    t.integer "assignee_id"
    t.integer "creator_id"
    t.integer "pair_assignee_id"
    t.integer "qa_tester_id"
    t.integer "story_point"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["assignee_id"], name: "index_stories_on_assignee_id"
    t.index ["creator_id"], name: "index_stories_on_creator_id"
    t.index ["guid"], name: "index_stories_on_guid", unique: true
    t.index ["pair_assignee_id"], name: "index_stories_on_pair_assignee_id"
    t.index ["qa_tester_id"], name: "index_stories_on_qa_tester_id"
    t.index ["reporter_id"], name: "index_stories_on_reporter_id"
  end

  add_foreign_key "change_logs", "members", column: "author_id"
  add_foreign_key "stories", "members", column: "assignee_id"
  add_foreign_key "stories", "members", column: "creator_id"
  add_foreign_key "stories", "members", column: "pair_assignee_id"
  add_foreign_key "stories", "members", column: "qa_tester_id"
  add_foreign_key "stories", "members", column: "reporter_id"
end
