class DropUploadFlag < ActiveRecord::Migration
  def up
    remove_column(:groups, 'widget_upload_capable')
  end
end
