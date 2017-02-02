class AddQuestionRejectFlags < ActiveRecord::Migration
  def change
    add_column(:questions, :rejection_code, :integer)
    add_index "questions", [:rejection_code], :name => "idx_rejections"
  end
end
