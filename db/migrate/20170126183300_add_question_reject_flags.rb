class AddQuestionRejectFlags < ActiveRecord::Migration
  def change
    add_column(:questions, :rejection_code, :integer)
  end
end
