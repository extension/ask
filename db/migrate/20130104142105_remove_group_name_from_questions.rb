class RemoveGroupNameFromQuestions < ActiveRecord::Migration
  def change
    remove_column :questions, :group_name
  end
end
