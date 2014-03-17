class AddInitialResponseFields < ActiveRecord::Migration
  def change
    execute "ALTER TABLE `questions` ADD COLUMN `initial_response_at` DATETIME NULL DEFAULT NULL  AFTER `initial_response_time`;"
    execute "ALTER TABLE `questions` ADD COLUMN `initial_responder_id` INT(11) NULL DEFAULT NULL  AFTER `initial_response_at`;"
    execute "UPDATE questions, responses SET questions.initial_response_at = responses.created_at, questions.initial_responder_id = responses.resolver_id WHERE questions.initial_response_id = responses.id"
    add_index "questions", ["initial_response_id", "initial_response_time", "initial_response_at", "initial_responder_id"], :name => "initial_response_ndx"
  end
end
