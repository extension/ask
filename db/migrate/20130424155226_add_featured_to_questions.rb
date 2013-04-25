class AddFeaturedToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :featured, :boolean, :default => false, :null => false
  end
end
