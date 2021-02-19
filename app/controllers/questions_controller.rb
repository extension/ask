# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class QuestionsController < ApplicationController
  before_filter :set_submitter, only: [:show]
  layout 'public'
  before_filter :set_format, :only => [:show, :submitter_view]

  def index
    # @recent_questions = filtered_questions.public_visible
  end

  def show
    @question = Question.find_by_id(params[:id])
    return record_not_found if !@question

    # redirect publicly viewable questions to Ask Extension in stages
    # redirect roughly 20%
    if(@question.resolved_at < '2015-03-01 00:00:00')
      ask2_url = "https://ask2.extension.org/kb/faq.php?id=" + @question.id.to_s
      return redirect_to(ask2_url,:status => :moved_permanently)
    end

    @question_responses = @question.responses

    analytics_url = []

    # if @question.tags.length != 0
    #   analytics_url = ["|tags"] + @question.tags.map(&:name)
    #   tracker do |t|
    #     t.google_tag_manager :push, { pageAttributes: @question.tags.map(&:name) }
    #   end
    # end

    question_resolves_with_resolver = @question.question_events.where('event_state = 2').includes(:initiator)

    if question_resolves_with_resolver.length > 0
      analytics_url += ["|experts"] + question_resolves_with_resolver.map{|qe| qe.initiator.login}.uniq
      tracker do |t|
        t.google_tag_manager :push, { questionExperts: question_resolves_with_resolver.map{|qe| qe.initiator.login}.uniq }
      end
    end

    if @question.assigned_group
      analytics_url += ["|group"] + [@question.assigned_group.name]
      tracker do |t|
        t.google_tag_manager :push, { assignedGroup: @question.assigned_group.name }
      end
    end

    if analytics_url.length > 0
      tracker do |t|
        t.google_tag_manager :push, { pageURL: question_path(@question.id) + "?" + analytics_url.join(",") }
      end
    end

    tracker do |t|
      t.google_tag_manager :push, { pageTitle: @question.title.html_safe }
    end

    # should this show as private?
    @private_view = true
    if(!@question.is_private?)
      @private_view = false
    end

    if(current_user and current_user.id == @question.submitter_id)
      setup_images_for_edit
      @private_view = false
    elsif (@authenticated_submitter && (@authenticated_submitter.id == @question.submitter_id) && (session[:question_id] == @question.id))
      setup_images_for_edit
      @private_view = false
    end

  end

  def submitter_view
    @question = Question.find_by_question_fingerprint(params[:fingerprint])
    # the hash will authenticate the question submitter to edit their question.
    if @question.present?
      flash.keep
      session[:question_id] = @question.id
      if(current_user and current_user.id == @question.submitter_id)
        redirect_to question_url(@question)
      elsif session[:submitter_id].present? && session[:submitter_id].to_i == @question.submitter_id
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
    if(!@question)
      return record_not_found
    end

    # validate that I can edit this question
    @can_edit = false
    if(current_user and current_user.id == @question.submitter_id)
      @can_edit = true
    elsif(session[:submitter_id].present? and session[:submitter_id].to_i == @question.submitter_id)
      @can_edit = true
    end

    if(@can_edit)
      if !@question.update_attributes(params[:question])
        flash[:notice] = "There was an error saving your question, please make sure the question field is not blank."
      else
        flash[:notice] = "Your changes have been saved. Thanks for making your question better!"
      end
      QuestionEvent.log_public_edit(@question)
    end
    redirect_to question_url(@question)
  end

  #TODO : incorporate title into this.
  def create
    if request.post?

      # check for the existence of the question parameter, if not present, the form parameters are not being passed
      if params[:question].blank?
        @status_message = "The question form is not complete. Please fill out all fields."
        return render(:template => '/widget/status', :layout => false)
      end

      @group = Group.find_by_widget_fingerprint(params[:fingerprint].strip) if !params[:fingerprint].blank?
      if(!@group)
        @status_message = "Unknown widget specified."
        return render(:template => '/widget/status', :layout => false)
      end

      # save the referrer so it doesn't get overwritten if the form is refreshed because of errors
      @widget_parent_url = (params[:widget_parent_url]) ? params[:widget_parent_url] : ''

      begin
        # setup the question to be saved and fill in attributes with parameters
        # remove all whitespace in question before putting into db.
        @question = Question.new(params[:question])

        if current_user and current_user.email.present?
          @submitter = current_user
        else
          if !(@submitter = User.find_by_email(params[:question][:submitter_email].strip))
            @submitter = User.new({:email => params[:question][:submitter_email].strip, :kind => 'PublicUser'})
            if !@submitter.valid?
              @argument_errors = ("Errors occurred when saving: " + @submitter.errors.full_messages.join(' '))
              raise ArgumentError
            end
          end
        end

        @question.submitter = @submitter
        @question.assigned_group = @group
        @question.original_group_id = @group.id
        @question.user_ip = request.remote_ip
        @question.user_agent = request.env['HTTP_USER_AGENT']
        @question.widget_parent_url = @widget_parent_url
        @question.status = Question::STATUS_TEXT[Question::STATUS_SUBMITTED]
        @question.status_state = Question::STATUS_SUBMITTED
        @question.source = Question::FROM_WIDGET

        # record the original location and county
        @question.original_location = @question.location
        @question.original_county = @question.county

        # set the yolo location/county as well
        @yolo.set_location(@question.location)
        @yolo.set_county(@question.county)

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

        # validate question
        if !@question.valid?
          @argument_errors = ("We ran into a problem: " + @question.errors.full_messages.join(' '))
          raise ArgumentError
        end

        if @question.save
          session[:question_id] = @question.id
          session[:submitter_id] = @submitter.id
          flash[:notice] = "Thank You! You can expect a response emailed to the address you provided."
          if params[:widget_type] == "js_widget"
            return redirect_to js_widget_url(:fingerprint => @group.widget_fingerprint, :widget_parent_url => @widget_parent_url), :layout => false
          else
            return redirect_to group_widget_url(:fingerprint => @group.widget_fingerprint), :layout => false
          end
        else
          raise InternalError
        end

      rescue ArgumentError => ae
        flash[:warning] = @argument_errors
        @host_name = request.host_with_port

        if @question.blank?
          @question = Question.new
          3.times do
            @question.images.build
          end
        end

        if params[:widget_type] == "js_widget"
          return render(:template => 'widget/js_widget', :layout => false)
        else
          return render(:template => 'widget/index', :layout => false)
        end
      rescue Exception => e
        notify_honeybadger(e)
        flash[:warning] = "An internal error has occurred. Please check back later."
        @host_name = request.host_with_port

        if @question.blank?
          @question = Question.new
          3.times do
            @question.images.build
          end
        end

        if params[:widget_type] == "js_widget"
          return render(:template => 'widget/js_widget', :layout => false)
        else
          return render(:template => 'widget/index', :layout => false)
        end
      end
    else
      flash[:notice] = 'Bad request. Only POST requests are accepted.'
      if params[:widget_type] == "js_widget"
        return redirect_to js_widget_url(:fingerprint => @group.widget_fingerprint, :widget_parent_url => @widget_parent_url), :layout => false
      else
        return redirect_to group_widget_url(:fingerprint => @group.widget_fingerprint), :layout => false
      end
    end
  end

  private

  def setup_images_for_edit
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

  def set_submitter
    if(!@authenticated_submitter = User.find_by_id(session[:submitter_id]))
      session[:submitter_id] = nil
    end
  end
end
