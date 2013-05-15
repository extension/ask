class AddFeaturedToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :featured, :boolean, :default => false, :null => false
    add_column :questions, :featured_at, :datetime
  end
end
