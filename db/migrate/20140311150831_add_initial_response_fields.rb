class AddInitialResponseFields < ActiveRecord::Migration
  def change
    execute "ALTER TABLE `questions` ADD COLUMN `initial_response_at` DATETIME NULL DEFAULT NULL  AFTER `initial_response_time`;"
    execute "UPDATE questions, responses SET questions.initial_response_at = responses.created_at WHERE questions.initial_response_id = responses.id"
    add_index "questions", ["initial_response_id", "initial_response_time", "initial_response_at"], :name => "initial_response_ndx"
  end
end
