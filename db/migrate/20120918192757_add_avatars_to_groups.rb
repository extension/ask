class AddAvatarsToGroups < ActiveRecord::Migration
  def change
    change_table :groups do |t|
      # paperclip method for generating necessary image columns
      t.has_attached_file :avatar
    end
  end
end
