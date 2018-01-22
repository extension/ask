class AddNullConstraint < ActiveRecord::Migration
  def up
    execute("ALTER TABLE `tags` CHANGE COLUMN `name` `name` VARCHAR(255) NOT NULL DEFAULT '';")
  end
end
