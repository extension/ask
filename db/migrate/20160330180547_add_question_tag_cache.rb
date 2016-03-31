class AddQuestionTagCache < ActiveRecord::Migration
  def change
    add_column :questions, :cached_tag_hash, :text
  end

  def down
  end
end
