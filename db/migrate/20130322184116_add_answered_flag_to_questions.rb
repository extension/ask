class AddAnsweredFlagToQuestions < ActiveRecord::Migration
  # adding ever answered flag so in things like reports, we don't have to join on question_events every time and look for 
  # questions that have been answered, we can get this information from this flag
  def change
    add_column :questions, :ever_answered, :boolean, :null => false, :default => false
    
    Question.select("DISTINCT(questions.id), questions.*").joins(:question_events).where("event_state = #{QuestionEvent::RESOLVED}").each do |q|
      q.update_column(:ever_answered, true)
    end
  end
end
