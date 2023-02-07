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

ActiveRecord::Schema.define(version: 2023_02_07_150812) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "climbs", force: :cascade do |t|
    t.text "climber"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "current"
    t.json "route_state_json", default: []
    t.date "climbed_at"
  end

  create_table "places", force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "route_sets", force: :cascade do |t|
    t.text "color"
    t.datetime "added"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "place_id"
    t.date "expires_at"
    t.index ["place_id"], name: "index_route_sets_on_place_id"
  end

  create_table "route_states", force: :cascade do |t|
    t.bigint "climb_id"
    t.bigint "route_id"
    t.integer "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["climb_id"], name: "index_route_states_on_climb_id"
    t.index ["route_id"], name: "index_route_states_on_route_id"
  end

  create_table "routes", force: :cascade do |t|
    t.bigint "route_set_id"
    t.integer "pos_x"
    t.integer "pos_y"
    t.datetime "added"
    t.integer "floor"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["route_set_id"], name: "index_routes_on_route_set_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "reference"
    t.bigint "place_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["place_id"], name: "index_users_on_place_id"
  end

  add_foreign_key "route_sets", "places"
end
