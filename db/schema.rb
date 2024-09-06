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

ActiveRecord::Schema[7.1].define(version: 2024_09_06_104512) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "climbs", force: :cascade do |t|
    t.text "climber"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "current"
    t.json "route_state_json", default: []
    t.date "climbed_at"
  end

  create_table "climbs_route_sets", force: :cascade do |t|
    t.bigint "climb_id", null: false
    t.bigint "route_set_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["climb_id", "route_set_id"], name: "index_climbs_route_sets_on_climb_id_and_route_set_id", unique: true
    t.index ["climb_id"], name: "index_climbs_route_sets_on_climb_id"
    t.index ["route_set_id"], name: "index_climbs_route_sets_on_route_set_id"
  end

  create_table "floorplans", force: :cascade do |t|
    t.bigint "place_id", null: false
    t.text "name", null: false
    t.jsonb "data", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["place_id"], name: "index_floorplans_on_place_id"
  end

  create_table "grades", force: :cascade do |t|
    t.bigint "place_id", null: false
    t.string "name"
    t.string "grade"
    t.string "map_tint_colour"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["place_id"], name: "index_grades_on_place_id"
  end

  create_table "places", force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_places_on_user_id"
  end

  create_table "route_sets", force: :cascade do |t|
    t.datetime "added", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "place_id", null: false
    t.date "expires_at"
    t.bigint "route_set_colour_set_colour_id"
    t.bigint "grade_id"
    t.index ["grade_id"], name: "index_route_sets_on_grade_id"
    t.index ["place_id"], name: "index_route_sets_on_place_id"
    t.index ["route_set_colour_set_colour_id"], name: "index_route_sets_on_route_set_colour_set_colour_id"
  end

  create_table "route_states", force: :cascade do |t|
    t.bigint "climb_id"
    t.bigint "route_id"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["climb_id"], name: "index_route_states_on_climb_id"
    t.index ["route_id"], name: "index_route_states_on_route_id"
  end

  create_table "routes", force: :cascade do |t|
    t.bigint "route_set_id"
    t.integer "pos_x"
    t.integer "pos_y"
    t.datetime "added", precision: nil
    t.integer "floor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["route_set_id"], name: "index_routes_on_route_set_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "reference"
    t.bigint "place_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["place_id"], name: "index_users_on_place_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "climbs_route_sets", "climbs"
  add_foreign_key "climbs_route_sets", "route_sets"
  add_foreign_key "floorplans", "places"
  add_foreign_key "grades", "places"
  add_foreign_key "route_sets", "grades"
  add_foreign_key "route_sets", "places"
end
