class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.string   :type
      t.integer :assetable_id
      t.string :assetable_type
      # paperclip method for generating needed image columns
      t.has_attached_file :attachment
      t.timestamps
    end
  end
end
