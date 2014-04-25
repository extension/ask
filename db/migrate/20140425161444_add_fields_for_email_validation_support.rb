class AddFieldsForEmailValidationSupport < ActiveRecord::Migration
  def change
    add_column :users, :has_invalid_email, :boolean, default: false
    add_column :users, :invalid_email, :string
  end
end
