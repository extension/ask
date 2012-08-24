class QuestionsController < ApplicationController
  layout 'public'
  
  def show
    @question = Question.find_by_id(params[:id])
    
    if @question.is_private?
      redirect_to home_private_page_url
    end
    
    @question_responses = @question.responses
    @fake_related = Question.public_visible.find(:all, :limit => 3, :offset => rand(Question.count))
  end
  
  # TODO: incorporate title into this.
  def create  
    if request.post?
      @group = Group.find_by_widget_fingerprint(params[:fingerprint].strip) if !params[:fingerprint].blank?
      if(!@group)
        @status_message = "Unknown widget specified."
        return render(:template => '/widget/status', :layout => false)
      end
      begin
        # setup the question to be saved and fill in attributes with parameters
        # remove all whitespace in question before putting into db.
        @question = Question.new(params[:question])
        @email_confirmation = params[:email_confirmation].strip
        
        # make sure email and confirmation email match up
        if @question.submitter_email != @email_confirmation
          @argument_errors = "Email address does not match the confirmation email address."
          raise ArgumentError
        end

        if !(@submitter = User.find_by_email(@question.submitter_email))
          @submitter = User.create({:email => @question.submitter_email})
          if !@submitter.valid?
            @argument_errors = ("Errors occured when saving:<br />" + @submitter.errors.full_messages.join('<br />'))
            raise ArgumentError
          end
        end
        
        @question.submitter = @submitter
        @question.assigned_group = @group
        @question.group_name = @group.name
        @question.user_ip = request.remote_ip
        @question.user_agent = request.env['HTTP_USER_AGENT']
        @question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
        @question.status = Question::SUBMITTED_TEXT
        @question.status_state = Question::STATUS_SUBMITTED
        
        if !@group.widget_public_option
          @question.is_private = true
          # in this case, the check box does not show for privacy for the submitter, everything that comes through this group is private,
          # so we default to the submitter marking private and this way, it cannot be overridden by an expert, when we don't know what 
          # the submitter wanted, we default to the safest thing, privacy by the submitter.
          @question.is_private_reason = Question::PRIVACY_REASON_SUBMITTER
        else
          @question.is_private ? (@question.is_private_reason = Question::PRIVACY_REASON_SUBMITTER) : (@question.is_private_reason = Question::PRIVACY_REASON_PUBLIC)
        end  
        
        # TODO: Need to update this
        # # location and county - separate from params[:submitted_question], but probably shouldn't be
        #         if(params[:location_id] and location = Location.find_by_id(params[:location_id].strip.to_i))
        #           @question.location = location
        #           # change session if different
        #           if(!session[:location_and_county].blank?)
        #             if(session[:location_and_county][:location_id] != location.id)
        #               session[:location_and_county] = {:location_id => location.id}
        #             end
        #           else
        #             session[:location_and_county] = {:location_id => location.id}
        #           end
        #           if(params[:county_id] and county = County.find_by_id_and_location_id(params[:county_id].strip.to_i, location.id))
        #             @question.county = county
        #             if(!session[:location_and_county][:county_id].blank?)
        #               if(session[:location_and_county][:county_id] != county.id)
        #                 session[:location_and_county][:county_id] = county.id
        #               end
        #             else
        #               session[:location_and_county][:county_id] = county.id
        #             end
        #           end
        #         elsif(@group.location_id)
        #           @question.location_id = @group.location_id
        #           if(@group.county_id)
        #             @question.county_id = @group.county_id
        #           end
        #         end
        
        # validate question
        if !@question.valid?
          @argument_errors = ("Errors occured when saving:<br />" + @question.errors.full_messages.join('<br />'))
          raise ArgumentError
        end
        
        # TODO: Update this    
        # # handle image upload
        #         if !params[:image].blank?
        #           photo_to_upload = FileAttachment.create({:attachment => params[:image]}) 
        #           if !photo_to_upload.valid?
        #             @argument_errors = "Errors occured when uploading your image:<br />" + photo_to_upload.errors.full_messages.join('<br />')        
        #             raise ArgumentError
        #           else
        #             @question.file_attachments << photo_to_upload
        #           end   
        #         end
        #         # end of handling image upload
        
        if @question.save
          #session[:account_id] = @submitter.id
          #TODO: keep???
          # tags
          # if(@group.widget_enable_tags?)
          #             if(!params[:tag_list])
          #               @question.tag_myself_with_shared_tags(@widget.system_sharedtags_displaylist)
          #             end
          #           end
          flash[:notice] = "Thank You! You can expect a response emailed to the address you provided."
          return redirect_to group_widget_url(:fingerprint => @group.widget_fingerprint), :layout => false
        else
          raise InternalError
        end
      
      rescue ArgumentError => ae
        flash[:warning] = @argument_errors
        @host_name = request.host_with_port
        if(@group.is_bonnie_plants?)
          return render(:template => 'widget/bonnie_plants', :layout => false)
        else
          return render(:template => 'widget/index', :layout => false)
        end
      #rescue Exception => e
      #  flash[:notice] = 'An internal error has occured. Please check back later.'
      #  @host_name = request.host_with_port
      #  if(@group.is_bonnie_plants?)
      #    return render(:template => 'widget/bonnie_plants', :layout => false)
      #  else
      #    return render(:template => 'widget/index', :layout => false)
      #  end
      end
    else
      flash[:notice] = 'Bad request. Only POST requests are accepted.'
      return redirect_to group_widget_url(:fingerprint => @group.widget_fingerprint), :layout => false
    end
  end
end
