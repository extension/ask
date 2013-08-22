class AddReasonToVersions < ActiveRecord::Migration
  # also add notify_submitter flag to log whether the submitter was notified of the change or not
  def change
    add_column :versions, :reason, :text, null: true
    add_column :versions, :notify_submitter, :boolean, null: false, default: false
  end
end
