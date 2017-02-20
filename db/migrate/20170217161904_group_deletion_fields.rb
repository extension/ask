class GroupDeletionFields < ActiveRecord::Migration
  def change
    add_column(:question_events, :group_logs, :text)
    add_index "question_events", [:recipient_group_id, :previous_group_id, :changed_group_id], :name => "group_ndx"

  end
end
