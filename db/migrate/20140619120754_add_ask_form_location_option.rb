class AddAskFormLocationOption < ActiveRecord::Migration
  def change
    add_column :groups, :ask_form_show_location, :boolean, default: true
  end

end
