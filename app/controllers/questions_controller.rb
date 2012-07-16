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
  
  def create  
    if request.post?
      @group = Group.find_by_fingerprint(params[:fingerprint].strip) if !params[:fingerprint].blank?
      if(!@group)
        @status_message = "Unknown widget specified."
        return render(:template => '/widget/status', :layout => false)
      end
      begin
        # setup the question to be saved and fill in attributes with parameters
        # remove all whitespace in question before putting into db.
        
        
        
        
        
        
        @email = params[:email].strip
        @email_confirmation = params[:email_confirmation].strip
        @question = params[:question].strip
        @first_name = params[:first_name].strip if !params[:first_name].blank?
        @last_name = params[:last_name].strip if !params[:last_name].blank?
        
        # make sure email and confirmation email match up
        if @email != @email_confirmation
          @argument_errors = "Email address does not match the confirmation email address."
          raise ArgumentError
        end

        # name_hash just lets me update @submitter more easily
        name_hash = {}
        name_hash[:first_name] = @first_name 
        name_hash[:last_name] = @last_name
        
        if(@submitter = Account.find_by_email(@email))
          if(@submitter.first_name == 'Anonymous' or @submitter.last_name == 'Guest')
            @submitter.update_attributes(name_hash)
          end
        else
          @submitter = PublicUser.create({:email => @email}.merge(name_hash))
          if !@submitter.valid?
            @argument_errors = ("Errors occured when saving:<br />" + @submitter.errors.full_messages.join('<br />'))
            raise ArgumentError
          end
        end
        
        @question = Question.new
        @question.submitter = @submitter
        @question.widget = @widget
        @question.widget_name = @widget.name
        @question.user_ip = request.remote_ip
        @question.user_agent = request.env['HTTP_USER_AGENT']
        @question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
        @question.status = SubmittedQuestion::SUBMITTED_TEXT
        @question.status_state = SubmittedQuestion::STATUS_SUBMITTED
        @question.external_app_id = 'widget'
        @question.submitter_email = @submitter.email
        @question.submitter_firstname = @submitter.first_name
        @question.submitter_lastname = @submitter.last_name
        @question.asked_question = @question 
        

        # location and county - separate from params[:submitted_question], but probably shouldn't be
        if(params[:location_id] and location = Location.find_by_id(params[:location_id].strip.to_i))
          @question.location = location
          # change session if different
          if(!session[:location_and_county].blank?)
            if(session[:location_and_county][:location_id] != location.id)
              session[:location_and_county] = {:location_id => location.id}
            end
          else
            session[:location_and_county] = {:location_id => location.id}
          end
          if(params[:county_id] and county = County.find_by_id_and_location_id(params[:county_id].strip.to_i, location.id))
            @question.county = county
            if(!session[:location_and_county][:county_id].blank?)
              if(session[:location_and_county][:county_id] != county.id)
                session[:location_and_county][:county_id] = county.id
              end
            else
              session[:location_and_county][:county_id] = county.id
            end
          end
        elsif(@group.location_id)
          @question.location_id = @group.location_id
          if(@group.county_id)
            @question.county_id = @group.county_id
          end
        end
        
        # validate question
        if !@question.valid?
          @argument_errors = ("Errors occured when saving:<br />" + @question.errors.full_messages.join('<br />'))
          raise ArgumentError
        end
            
        # handle image upload
        if !params[:image].blank?
          photo_to_upload = FileAttachment.create({:attachment => params[:image]}) 
          if !photo_to_upload.valid?
            @argument_errors = "Errors occured when uploading your image:<br />" + photo_to_upload.errors.full_messages.join('<br />')        
            raise ArgumentError
          else
            @question.file_attachments << photo_to_upload
          end   
        end
        # end of handling image upload
        
        if @question.save
          session[:account_id] = @submitter.id
          # tags
          if(@group.widget_enable_tags?)
            if(!params[:tag_list])
              @question.tag_myself_with_shared_tags(@widget.system_sharedtags_displaylist)
            end
          end
          flash[:notice] = "Thank You! You can expect a response emailed to the address you provided."
          return redirect_to widget_tracking_url(:widget => @widget.fingerprint), :layout => false
        else
          raise InternalError
        end
      
      rescue ArgumentError => ae
        flash[:warning] = @argument_errors
        @host_name = request.host_with_port
        if(@widget.is_bonnie_plants_widget?)
          return render(:template => 'widget/bonnie_plants', :layout => false)
        else
          return render(:template => 'widget/index', :layout => false)
        end
      rescue Exception => e
        flash[:notice] = 'An internal error has occured. Please check back later.'
        @host_name = request.host_with_port
        if(@widget.is_bonnie_plants_widget?)
          return render(:template => 'widget/bonnie_plants', :layout => false)
        else
          return render(:template => 'widget/index', :layout => false)
        end
      end
    else
      flash[:notice] = 'Bad request. Only POST requests are accepted.'
      return redirect_to widget_tracking_url(:widget => @widget.fingerprint), :layout => false
    end
  end
end
