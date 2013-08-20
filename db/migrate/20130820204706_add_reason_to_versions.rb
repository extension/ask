class AddReasonToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :reason, :text, null: true
  end
end
