class AddDataCacheVersion < ActiveRecord::Migration
  def change
    add_column :question_data_caches, :version, :integer, default: 1
  end
end
