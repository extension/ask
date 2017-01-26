# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class GroupsController < ApplicationController
  layout 'public'

  before_filter :set_format, :only => [:ask]
  invisible_captcha only: [:create]

  def show
    @group = Group.find(params[:id])
    @group_tags = @group.tags
    @open_questions_col_one = @group.questions.public_visible.find(:all, :limit => 5, :order => 'created_at DESC')
    @open_questions_col_two = @group.questions.public_visible.find(:all, :limit => 5, :offset => 5, :order => 'created_at DESC')
  end

  def ask_widget
    # asynchronous js loading code was taken from this tutorial:
    # http://blog.swirrl.com/articles/creating-asynchronous-embeddable-javascript-widgets/

    @group = Group.find(params[:id])
    @question = Question.new

    # the initial iteration of the widget snippet included both group ID and
    # fingerprint in the url. The fingerprint was removed to simplify the code, but some
    # widgets had already been installed. Once all first iteration widgets have
    # been accounted for, the fingerprint check can be removed
    @widget_div_id = params.has_key?(@group.widget_fingerprint) ? @group.widget_fingerprint : "aae-#{@group.id}"

    # display three image fields for question submitter
    3.times do
      @question.images.build
    end

    respond_to do |format|
      format.js {render :ask_widget}
    end
  end


  def ask
    @group = Group.find(params[:id])
    # redirect if question wrangler group

    if(@group.id == Group::QUESTION_WRANGLER_GROUP_ID)
      return redirect_to(ask_index_path)
    end

    # no linking directly to this form when a group doesn't
    # take questions outside the location
    if(!@group.assignment_outside_locations? and !refered_from_our_site?)
      return redirect_to(ask_index_path)
    end

    params[:fingerprint] = @group.widget_fingerprint
    @question = Question.new

    # display three image fields for question submitter
    3.times do
      @question.images.build
    end
  end

  def create
    @group = Group.find(params[:id])

    # check for the existence of the question parameter, if not present, the form parameters are not being passed
    if params[:question].blank?
      flash[:error] = "The question form is not complete. Please fill out all fields."
      return redirect_to ask_group_url(id: @group.id)
    end

    begin
      @question = Question.new(params[:question])
    rescue
      flash[:error] = "Invalid Parameters."
      return redirect_to ask_group_url(id: @group.id)
    end

    if current_user and current_user.email.present?
      @submitter = current_user
    else
      if !(@submitter = User.find_by_email(params[:question][:submitter_email].strip))
        @submitter = User.new({:email => params[:question][:submitter_email].strip, :kind => 'PublicUser'})
        if !@submitter.valid?
          #TODO : to be sure there's a better way to combine errors?
          @submitter.errors.each do |attribute,message|
            # message could be an array, but not going to be for User
            @question.errors[attribute] = message
          end
          3.times do
            @question.images.build
          end
          return render(action: 'ask')
        end
      end
    end

    @question.submitter = @submitter
    @question.assigned_group = @group
    @question.original_group_id = @group.id
    @question.user_ip = request.remote_ip
    @question.user_agent = request.env['HTTP_USER_AGENT']
    @question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
    @question.status = Question::STATUS_TEXT[Question::STATUS_SUBMITTED]
    @question.status_state = Question::STATUS_SUBMITTED

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



    if @question.save
      if(!@question.spam?)
        session[:question_id] = @question.id
        session[:submitter_id] = @submitter.id
        redirect_to(@question, :notice => 'Question was successfully created.')
      else
        redirect_to(root_url)
      end
    else
      flash.now[:error] = "Missing Parameters."
      return render(action: 'ask')
    end
  end


  # convenience method to redirect to a widget page for the group
  def widget
    @group = Group.find(params[:id])
    return redirect_to group_widget_url(fingerprint: @group.widget_fingerprint)
  end

end
