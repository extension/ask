class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string   :type
      t.integer :attachable_id
      t.string :attachable_type
      # paperclip method for generating needed image columns
      t.has_attached_file :attachment
      t.timestamps
    end
  end
end
