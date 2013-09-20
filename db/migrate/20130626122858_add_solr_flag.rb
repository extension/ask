class AddSolrFlag < ActiveRecord::Migration
  def change
    add_column :users, :needs_search_update, :boolean
    add_index :users, :needs_search_update, :name => 'search_update_flag_ndx'
  end

end
