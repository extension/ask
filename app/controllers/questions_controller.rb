# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class QuestionsController < ApplicationController
  before_filter :set_submitter, only: [:show]
  skip_before_filter :verify_authenticity_token, :set_yolo, only: [:account_review_request]
  layout 'public'

  def show
    @question = Question.find_by_id(params[:id])
    @question_responses = @question.responses
    
    ga_tracking = []
    
    if @question.tags.length > 0
      ga_tracking = ["|tags"] + @question.tags.map(&:name)
    end
    
    question_resolves_with_resolver = @question.question_events.where('event_state = 2').includes(:initiator)
    
    if question_resolves_with_resolver.length > 0
      ga_tracking += ["|experts"] + question_resolves_with_resolver.map{|qe| qe.initiator.login}.uniq
    end
    
    if @question.assigned_group
      ga_tracking += ["|group"] + [@question.assigned_group.name]
    end
    
    if ga_tracking.length > 0
      flash.now[:googleanalytics] = question_path(@question.id) + "?" + ga_tracking.join(",")
    end
    
    if session[:submitter_id].present? 
      if (@authenticated_submitter and @authenticated_submitter.id == @question.submitter.id and session[:question_id] == @question.id)
        @response = Response.new
        3.times do    
          @response.images.build
        end

        # max of 3 total images allowed (including existing)
        new_image_count = 3 - @question.images.count
        if new_image_count > 0
          new_image_count.times do    
            @question.images.build
          end
        end
      end
    end

    # should this show as private?
    @private_view = true
    if(!@question.is_private?)
      @private_view = false
    elsif(@authenticated_submitter and @authenticated_submitter.id == @question.submitter_id and session[:question_id] == @question.id)
      @private_view = false
    end
    
    if(current_user or session[:submitter_id])
      @viewer = current_user.present? ? current_user : User.find_by_id(session[:submitter_id])
      @last_viewed_at = @viewer.last_view_for_question(@question)
      # log view
      QuestionViewlog.log_view(@viewer,@question)
    end


  end
  
  def submitter_view
    @question = Question.find_by_question_fingerprint(params[:fingerprint])
    # the hash will authenticate the question submitter to edit their question.
    if @question.present?
      session[:question_id] = @question.id
      if session[:submitter_id].present? && session[:submitter_id].to_i == @question.submitter.id
        redirect_to question_url(@question)
      else
        return render :template => 'questions/submitter_signin'
      end
    else
      return record_not_found
    end
  end
  
  def authorize_submitter
    @question = Question.find_by_question_fingerprint(params[:fingerprint])

    return record_not_found if !@question

    if params[:email_address].present? && (submitter = User.find_by_email(params[:email_address].strip.downcase)) 
      # make sure that this question belongs to this user
      if(@question.submitter.id == submitter.id)
        session[:submitter_id] = submitter.id
        session[:question_id] = @question.id
        return redirect_to question_url(@question)
      end
    end

    flash.now[:warning] = "The email address you entered does not match the email used to submit the question. Please check the email address and try again."
    render :template => 'questions/submitter_signin'
  end
    
  def update
    @question = Question.find_by_id(params[:id])
    if !@question.update_attributes(params[:question])
      flash[:notice] = "There was an error saving your question, please make sure the question field is not blank."
    else
      flash[:notice] = "Your changes have been saved. Thanks for making your question better!"
    end
    
    QuestionEvent.log_public_edit(@question)
    
    redirect_to question_url(@question)
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

        # Need to check with Bonnie Plants before removing email confirmation option from their widget. In the meantime, handle it as an optional field
        @email_confirmation = params[:email_confirmation] ? params[:email_confirmation].strip : params[:question][:submitter_email]

        # make sure email and confirmation email match up
        if params[:question][:submitter_email] != @email_confirmation
          @argument_errors = "Email address does not match the confirmation email address."
          raise ArgumentError
        end

        if !(@submitter = User.find_by_email(params[:question][:submitter_email]))
          @submitter = User.new({:email => params[:question][:submitter_email], :kind => 'PublicUser'})
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
        elsif params[:is_public].present? && params[:is_public] == '1'
          # For UX, the input label is the opposite of the flag. If the checkbox is checked, the question is public
          @question.is_private = false
          @question.is_private_reason = Question::PRIVACY_REASON_PUBLIC
        else
          @question.is_private = true
          @question.is_private_reason = Question::PRIVACY_REASON_SUBMITTER
        end

        # if the person overrode location/county - set those session values

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

        if @question.save
          session[:question_id] = @question.id
          session[:submitter_id] = @submitter.id
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
      rescue Exception => e
        flash[:notice] = 'An internal error has occured. Please check back later.'
        @host_name = request.host_with_port
        if(@group.is_bonnie_plants?)
          return render(:template => 'widget/bonnie_plants', :layout => false)
        else
          return render(:template => 'widget/index', :layout => false)
        end
      end
    else
      flash[:notice] = 'Bad request. Only POST requests are accepted.'
      return redirect_to group_widget_url(:fingerprint => @group.widget_fingerprint), :layout => false
    end
  end

  def account_review_request
    # check parameters
    if(!params[:fullname] or !params[:idstring] or !params[:email] or !params[:account_review_key])
      returninformation = {'message' => 'Missing parameters', 'success' => false}
      return render :json => returninformation.to_json, :status => :unprocessable_entity
    end

    # check reviewkey
    if(params[:account_review_key] != Settings.account_review_key)
      returninformation = {'message' => 'Review key does not match', 'success' => false}
      return render :json => returninformation.to_json, :status => :unprocessable_entity
    end

    # signup affiliation text
    if(params[:additional_information])
      additional_information = <<-MOARINFO.strip_heredoc
        Additional information from #{params[:fullname]} about their Extension involvement:

        #{Question.html_to_text(params[:additional_information])}
      MOARINFO
    else
      additional_information = ''
    end

    review_text = <<-REVIEWTEXT.strip_heredoc
      This is a system-generated account review request on behalf of:

      #{params[:fullname]}
      #{params[:email]}

      #{additional_information}
      Please vouch for the account at:

      https://people.extension.org/colleagues/showuser/#{params[:idstring]}

      Accounts not vouched with 14 days will automatically be retired. If you are a people
      administrator, please go ahead and retire the account if it cannot be vouched for.
    REVIEWTEXT


    if !(@submitter = User.find_by_email(params[:email]))
      @submitter = User.new({:email => params[:email], :kind => 'PublicUser'})
      if !@submitter.valid?
        returninformation = {'message' => @submitter.errors.full_messages.join("\n"), 'success' => false}
        return render :json => returninformation.to_json, :status => :unprocessable_entity
      end
    end

    @question = Question.new
    @question.is_private = true
    @question.title = 'Account Review Request'
    @question.body = review_text
    @question.submitter = @submitter
    @question.assigned_group = Group.support_group
    @question.user_ip = request.remote_ip
    @question.user_agent = (request.env['HTTP_USER_AGENT'] ? request.env['HTTP_USER_AGENT'] : '')
    @question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
    @question.status = Question::SUBMITTED_TEXT
    @question.status_state = Question::STATUS_SUBMITTED
    # TODO: review - this make no sense to me - jayoung
    @question.group_name = @question.assigned_group.name
    if(@question.save)
      returninformation = {'question_id' => @question.id, 'success' => true}
      return render :json => returninformation.to_json, :status => :ok
    else
      returninformation = {'message' => @question.errors.full_messages.join("\n"), 'success' => false}
      return render :json => returninformation.to_json, :status => :unprocessable_entity
    end
  end

  private

  def set_submitter
    if(!@authenticated_submitter = User.find_by_id(session[:submitter_id]))
      session[:submitter_id] = nil
    end
  end
end
