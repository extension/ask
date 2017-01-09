class DropYolos < ActiveRecord::Migration
  def change
    drop_table(:yo_los)
  end
end
