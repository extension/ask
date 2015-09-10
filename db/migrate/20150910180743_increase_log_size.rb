class IncreaseLogSize < ActiveRecord::Migration
  def up
    change_column :tag_edit_logs, :affected, :text, :limit => 16777215
  end
end
