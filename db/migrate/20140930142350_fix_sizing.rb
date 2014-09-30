class FixSizing < ActiveRecord::Migration
  def up
    change_column(:widget_logs, :referrer_url, :text)
    execute "ALTER TABLE `questions` CHANGE `referrer` `referrer` text"
    execute "ALTER TABLE `questions` CHANGE `user_agent` `user_agent` text"
    change_column(:evaluation_answers, :value, :bigint)
  end
end
