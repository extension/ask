class UpdateColumnsToNullable < ActiveRecord::Migration
  def change
    change_column :questions, :submitter_firstname, :string, :null => true
    change_column :questions, :submitter_lastname, :string, :null => true
  end
end
