class AddDetailsToQuestionEvents < ActiveRecord::Migration
  def change
    add_column :question_events, :changed_tag, :string
    add_index :question_events, :changed_tag
    
    QuestionEvent.reset_column_information
    
    # TAG_CHANGE = 8
    QuestionEvent.where(event_state: 8).each do |e|
      
      tags_array = []
      previous_tags_array = []

      tags_array << e.tags.split(',')
      previous_tags_array << e.previous_tags.split(',')

      if e.tags.length > e.previous_tags.length
        # a tag was added
        # ADDED_TAG = 23
        tag = tags_array - previous_tags_array
        e.update_column(:changed_tag,tag[0])
        e.update_column(:event_state,23)
      elsif e.previous_tags.length > e.tags.length
        # a tag was deleted
        # DELETED_TAG = 24
        tag = previous_tags_array - tags_array
        e.update_column(:changed_tag,tag[0])
        e.update_column(:event_state,24)
      else 
        # do nothing. not sure why or how the event was recorded
      end
      
    end
  end
end