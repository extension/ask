# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer  "rateable_id",   :null => false
      t.string   "rateable_type", :null => false
      t.integer  "score",         :null => false
      t.integer  "user_id"
      t.timestamps
    end
  end
end
