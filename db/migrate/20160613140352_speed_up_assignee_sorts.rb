class SpeedUpAssigneeSorts < ActiveRecord::Migration
  def change
    add_column(:users, :open_question_count, :integer, nil: false, default: 0)
    add_column(:users, :last_question_touched_at, :datetime)
    add_column(:users, :last_question_assigned_at, :datetime)
  end
end
