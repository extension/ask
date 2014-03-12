class AddExtensionFlagToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :submitter_is_extension, :boolean, default: false
    execute "UPDATE questions, users SET questions.submitter_is_extension = 1 WHERE questions.submitter_id = users.id and users.kind = 'User'"
  end
end
