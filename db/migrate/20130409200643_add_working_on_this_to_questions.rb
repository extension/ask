class AddWorkingOnThisToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :working_on_this, :datetime
  end
end
