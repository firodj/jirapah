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

ActiveRecord::Schema.define(version: 2020_11_05_154620) do

  create_table "change_logs", force: :cascade do |t|
    t.string "guid"
    t.integer "story_id"
    t.integer "author_id"
    t.text "description"
    t.datetime "changed_at"
    t.index ["author_id"], name: "index_change_logs_on_author_id"
    t.index ["guid"], name: "index_change_logs_on_guid", unique: true
    t.index ["story_id"], name: "index_change_logs_on_story_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "guid"
    t.integer "story_id"
    t.integer "author_id"
    t.integer "editor_id"
    t.datetime "posted_at"
    t.datetime "changed_at"
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["editor_id"], name: "index_comments_on_editor_id"
    t.index ["guid"], name: "index_comments_on_guid", unique: true
    t.index ["story_id"], name: "index_comments_on_story_id"
  end

  create_table "epics", force: :cascade do |t|
    t.string "title"
    t.string "key"
    t.integer "story_id", null: false
    t.index ["story_id"], name: "index_epics_on_story_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "guid"
    t.string "name"
    t.index ["guid"], name: "index_members_on_guid", unique: true
  end

  create_table "sprints", force: :cascade do |t|
    t.string "guid"
    t.string "name"
    t.index ["guid"], name: "index_sprints_on_guid", unique: true
  end

  create_table "sprints_stories", force: :cascade do |t|
    t.integer "sprint_id"
    t.integer "story_id"
    t.index ["sprint_id"], name: "index_sprints_stories_on_sprint_id"
    t.index ["story_id"], name: "index_sprints_stories_on_story_id"
  end

  create_table "stories", force: :cascade do |t|
    t.string "guid"
    t.string "key"
    t.text "summary"
    t.string "epic_link"
    t.string "project_guid"
    t.integer "reporter_id"
    t.integer "assignee_id"
    t.integer "creator_id"
    t.integer "story_points"
    t.text "labels"
    t.string "status"
    t.string "status_guid"
    t.string "resolution"
    t.string "resolution_guid"
    t.datetime "resolved_at"
    t.datetime "changed_at"
    t.datetime "posted_at"
    t.string "kind"
    t.string "kind_guid"
    t.integer "epic_id"
    t.integer "parent_id"
    t.string "parent_key"
    t.string "parent_guid"
    t.index ["assignee_id"], name: "index_stories_on_assignee_id"
    t.index ["creator_id"], name: "index_stories_on_creator_id"
    t.index ["guid"], name: "index_stories_on_guid", unique: true
    t.index ["parent_id"], name: "index_stories_on_parent_id"
    t.index ["reporter_id"], name: "index_stories_on_reporter_id"
  end

  add_foreign_key "change_logs", "members", column: "author_id"
  add_foreign_key "comments", "members", column: "author_id"
  add_foreign_key "comments", "members", column: "editor_id"
  add_foreign_key "epics", "stories"
  add_foreign_key "stories", "members", column: "assignee_id"
  add_foreign_key "stories", "members", column: "creator_id"
  add_foreign_key "stories", "members", column: "reporter_id"
  add_foreign_key "stories", "stories", column: "parent_id"
end
