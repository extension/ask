class AddReportingTables < ActiveRecord::Migration
  def change

    create_table "weekly_question_stats", :force => true do |t|
      t.integer  "statable_id"
      t.string   "statable_type", limit: 25, null: false
      t.integer  "yearweek"
      t.integer  "year"
      t.integer  "week"
      t.date     "yearweek_date"
      t.integer  "questions"
      t.integer  "seen"
      t.float    "total"
      t.float    "per_page"
      t.float    "previous_week"
      t.float    "previous_year"
      t.float    "pct_change_week"
      t.float    "pct_change_year"
      t.float    "pct_99"
      t.float    "pct_95"
      t.float    "pct_90"
      t.float    "pct_75"
      t.float    "pct_50"
      t.float    "pct_25"
      t.float    "pct_10"
      t.datetime "created_at", null: false
    end

    add_index "weekly_question_stats", ["statable_id", "statable_type", "datatype", "metric", "yearweek", "year", "week"], :name => "recordsignature", :unique => true


  end

end
