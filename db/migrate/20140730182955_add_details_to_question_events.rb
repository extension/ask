class AddDetailsToQuestionEvents < ActiveRecord::Migration
  def change
    add_column :question_events, :added_tag, :string
    add_column :question_events, :deleted_tag, :string
    
    # TAG_CHANGE = 8
    tag_change_events = QuestionEvent.where(event_state == 8) 
    tag_change_events.each do |e|
      
      tags_array = []
      previous_tags_array = []

      tags_array << e.tags.split(',')
      previous_tags_array << e.previous_tags.split(',')

      if e.tags.length > e.previous_tags.length
        # a tag was added
        # ADDED_TAG = 23
        tag = tags_array - previous_tags_array
        e.update_column(:added_tag,tag[0])
        e.update_column(:event_state,23)
      end

      if e.previous_tags.length > e.tags.length
        # a tag was deleted
        # DELETED_TAG = 24
        tag = previous_tags_array - tags_array
        e.update_column(:deleted_tag,tag[0])
        e.update_column(:event_state,24)
      end
      
    end
  end
end