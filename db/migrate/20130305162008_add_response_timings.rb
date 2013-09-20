class AddResponseTimings < ActiveRecord::Migration
  def change

    add_column("responses","is_expert",:boolean)
    add_column("responses","previous_expert",:boolean)
    add_column("responses","time_since_submission",:integer)
    add_column("responses","time_since_last",:integer)
    add_index("responses", ["is_expert","previous_expert"], :name => "resonse_type_ndx")

    # is public setting
    execute("UPDATE responses SET is_expert = 1 WHERE submitter_id is NULL")
    execute("UPDATE responses SET is_expert = 0 WHERE resolver_id is NULL")

    # response.created_at adjustment
    say_with_time "Adjusting response created_at values" do 
      Response.joins(:question).where('responses.created_at = questions.created_at').all.each do |response|
        if(initial_resolved_event = response.question.question_events.where('event_state = 2').order('created_at ASC').first)
          if(initial_resolved_event.created_at != response.created_at)
            response.update_column(:created_at,initial_resolved_event.created_at)
          end
        elsif(initial_resolved_event = response.question.question_events.where('event_state = 7').order('created_at ASC').first)
          if(initial_resolved_event.created_at != response.created_at)
            response.update_column(:created_at,initial_resolved_event.created_at)
          end
        end
      end
    end

    # timings - not going to set this in a migration because it takes 
    # too long, and can be done in the console - leaving here as an 
    # commented out example and record of the data transformation to be
    # performed along with this code change
    # say_with_time "Setting timings" do 
    #   Response.find_each do |response|
    #     response.set_timings
    #   end
    # end    

  end
end
