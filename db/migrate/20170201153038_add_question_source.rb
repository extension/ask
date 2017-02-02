class AddQuestionSource < ActiveRecord::Migration
  def change
    add_column(:questions, :source, :integer)
    add_index "questions", [:source], :name => "source_ndx"

    # populate
    # aae version 1
    execute "UPDATE questions SET source = #{Question::FROM_WIDGET} WHERE questions.external_app_id = 'widget' AND questions.created_at < '#{Time.parse(Question::AAE_V2_TRANSITION)}'"
    execute "UPDATE questions SET source = #{Question::FROM_WEBSITE} WHERE (questions.external_app_id <> 'widget' or questions.external_app_id IS NULL) AND questions.created_at < '#{Time.parse(Question::AAE_V2_TRANSITION)}'"

    # aae version 2
    execute "UPDATE questions SET source = #{Question::FROM_WIDGET} WHERE questions.referrer LIKE '%widget%' AND questions.created_at >= '#{Time.parse(Question::AAE_V2_TRANSITION)}'"
    execute "UPDATE questions SET source = #{Question::FROM_WEBSITE} WHERE questions.referrer NOT LIKE '%widget%' AND questions.created_at >= '#{Time.parse(Question::AAE_V2_TRANSITION)}'"
  end

end
