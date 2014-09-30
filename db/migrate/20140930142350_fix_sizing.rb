class FixSizing < ActiveRecord::Migration
  def up
    change_column(:widget_logs, :referrer_url, :text)
    change_column(:questions, :referrer, :text)
    change_column(:questions, :user_agent, :text)
    change_column(:evaluation_answers, :value, :bigint)
  end
end
