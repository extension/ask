class AddDetailsToQuestionEvents < ActiveRecord::Migration
  def change
    add_column :question_events, :changed_tag, :string
    add_index :question_events, :changed_tag
    
    QuestionEvent.reset_column_information
    
    QuestionEvent.where(event_state: QuestionEvent::TAG_CHANGE).each do |e|
      
      tags_array = []
      previous_tags_array = []

      tags_array = e.tags.split(',')
      previous_tags_array = e.previous_tags.split(',')

      if tags_array.length > previous_tags_array.length
        # a tag was added
        tag = tags_array - previous_tags_array
        if tag.length == 1
          e.update_column(:changed_tag,tag[0])
          e.update_column(:event_state,QuestionEvent::ADDED_TAG)
        end
      elsif e.previous_tags.length > e.tags.length
        # a tag was deleted
        tag = previous_tags_array - tags_array
        if tag.length == 1
          e.update_column(:changed_tag,tag[0])
          e.update_column(:event_state,QuestionEvent::DELETED_TAG)
        end
      else 
        # do nothing. not sure why or how the event was recorded
      end
      
    end
  end
end