# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::GroupsController < ApplicationController
  layout 'expert'
  before_filter :signin_required


  def index
    @my_groups = current_user.group_memberships
    current_location.present? ? @groups_near_my_state = Group.with_expertise_location(current_location.id).assignable.limit(6) : @groups_near_my_state = []
    current_county.present? ? @groups_near_my_county = Group.with_expertise_county(current_county.id).assignable.limit(6) : @groups_near_my_county = []
  end

  def all
    @group_count = Group.all.length
    @groups = Group.page(params[:page]).order(:name)
  end

  def email_csv
    @group = Group.find(params[:id])
    @group_members = @group.joined
    respond_to do |format|
      format.csv { send_data User.to_csv(@group_members, ["first_name", "last_name", "email"]), :filename => "#{@group.name.gsub(' ', '_')}_Member_Emails.csv" }
    end
  end

  def auto_assignment_log
    @group = Group.find(params[:id])
    @assignment_log_entries = @group.auto_assignment_logs.order('created_at DESC').page(params[:page])
  end

  def about
    @group = Group.find(params[:id])
    @group_members = @group.joined.order('connection_type ASC').order("users.last_activity_at DESC")
    @group_members_route_from_anywhere = @group.joined.route_from_anywhere
  end

  def leaders
    @group = Group.find(params[:id])
    @group_members = @group.joined.order('connection_type ASC').order("users.last_activity_at DESC")
    @group_members_route_from_anywhere = @group.joined.route_from_anywhere
  end

  def show
    @group = Group.find(params[:id])
    @question_list = "Needs an Answer"
    @questions = @group.open_questions.page(params[:page]).order('created_at DESC')
    @question_count = @group.open_questions.length
    @group_members = @group.group_members_with_self_first(current_user, 5)
    @group_tags = @group.tags.limit(7).order('updated_at DESC')
  end

  def answered
    @group = Group.find(params[:id])
    @question_list = "Answered"
    @questions = @group.answered_questions.page(params[:page]).order('resolved_at DESC')
    @question_count = @group.answered_questions.length
    @group_members = @group.group_members_with_self_first(current_user, 5)
    @group_tags = @group.tags.limit(7).order('updated_at DESC')
    render :action => 'show'
  end

  def rejected
    @group = Group.find(params[:id])
    @question_list = "Rejected automatically due to location or expert unavailability"
    @questions = @group.questions.auto_rejected.page(params[:page]).order('resolved_at DESC')
    @question_count = @group.questions.auto_rejected.count
    @group_members = @group.group_members_with_self_first(current_user, 5)
    @group_tags = @group.tags.limit(7).order('updated_at DESC')
    render :action => 'show'
  end

  def members
    @group = Group.find(params[:id])
    @group_members = @group.joined.order('connection_type ASC').order("users.last_activity_at DESC")
    @handling_rates = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @group_members.map(&:id)})
  end

  def questions_by_tag
    @group = Group.find(params[:group_id])
    @tag = Tag.find_by_id(params[:tag_id])
    return record_not_found if (!@tag)
    @questions = Question.from_group(@group.id).tagged_with(@tag.id).not_rejected.order("questions.status_state ASC").limit(25)
  end

  def profile
    @group = Group.find(params[:id])
    if request.put?
      change_hash = Hash.new
      @group.attributes = params[:group]

      if params[:delete_avatar] && params[:delete_avatar] == "1"
        @group.avatar = nil
      end

      if @group.name_changed?
        change_hash[:name] = {:old => @group.name_was, :new => @group.name}
      end

      if @group.description_changed?
        if !(@group.description_was.nil? && @group.description == '')
          change_hash[:description] = {:old => @group.description_was, :new => @group.description}
        end
      end

      if @group.is_test_changed?
        change_hash[:test_group] = {:old => @group.is_test_was, :new => @group.is_test}
      end

      if @group.group_active_changed?
        # we don't allow the group to be marked active if no one is signed up for it
        if @group.group_active == true
          if @group.assignees.count == 0
            @group.group_active = false
            flash[:error] = "There must be at least one active member to activate a Group."
            return render nil
          end
        end
        change_hash[:group_active] = {:old => @group.group_active_was, :new => @group.group_active}
      end

      if @group.save
        GroupEvent.log_edited_attributes(@group, current_user, nil, change_hash)
        redirect_to(expert_group_profile_path, :notice => 'Profile was successfully updated.')
      else
        render :action => 'profile'
      end
    end
  end

  def locations
    @group = Group.find(params[:id])
    @locations = Location.order('fipsid ASC')
    @object = @group
  end

  def tags
    @group = Group.find(params[:id])
    @group_tags = @group.tags.order('name ASC')
  end

  def add_tag
    @group = Group.find(params[:id])
    @tag = @group.set_tag(params[:tag])
    if @tag.blank?
      render :nothing => true
    end
  end

  def remove_tag
    @group = Group.find(params[:id])
    tag = Tag.find(params[:tag_id])
    @group.tags.delete(tag)
  end


  def assignment_options
    @group = Group.find(params[:id])
    if request.put?
      change_hash = Hash.new
      @group.attributes = params[:group]

      if @group.assignment_outside_locations_changed?
        change_hash[:assignment_outside_locations] = {:old => @group.assignment_outside_locations_was.to_s, :new => @group.assignment_outside_locations.to_s}
      end

      if @group.individual_assignment_changed?
        change_hash[:individual_assignment] = {:old => @group.individual_assignment_was.to_s, :new => @group.individual_assignment.to_s}
      end

      if @group.ignore_county_routing_changed?
        change_hash[:ignore_county] = {:old => @group.ignore_county_routing_was.to_s, :new => @group.ignore_county_routing.to_s}
      end

      if @group.save
        GroupEvent.log_edited_attributes(@group, current_user, nil, change_hash)
        redirect_to(expert_group_assignment_options_path, :notice => 'Assignment preferences updated.')
      else
        render :action => 'assignment_options'
      end
    end
  end

  def widget
    @group = Group.find(params[:id])
    @widget_url = ask_widget_group_url + ".js"
    if request.put?
      @group.attributes = params[:group]
      change_hash = Hash.new

      if @group.widget_public_option_changed?
        change_hash[:public_option] = {:old => @group.widget_public_option_was.to_s, :new => @group.widget_public_option.to_s}
      end

      if @group.widget_show_title_changed?
        change_hash[:show_title] = {:old => @group.widget_show_title_was.to_s, :new => @group.widget_show_title.to_s}
      end

      if @group.save
        GroupEvent.log_edited_attributes(@group, current_user, nil, change_hash)
        redirect_to(expert_group_widget_path, :notice => 'Widget settings successfully updated.')
      else
        render :action => 'widget'
      end
    end
  end

  def history
    @group = Group.find(params[:id])
    @group_events = @group.group_events.order('created_at DESC')
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(params[:group])
    @group.created_by = current_user.id
    @group.set_fingerprint(current_user)
    if @group.save
      current_user.join_group(@group,"leader")
      GroupEvent.log_group_creation(@group, current_user, current_user)
      redirect_to(expert_group_path(@group.id), :notice => 'Group was successfully created.')
    else
      render :action => 'new'
    end
  end

  def join
    @group = Group.find(params[:id])
    current_user.join_group(@group,"member")
    @group_members = @group.group_members_with_self_first(current_user, 5)
  end

  def lead
    @group = Group.find(params[:id])
    current_user.join_group(@group,"leader")
    @group_members = @group.group_members_with_self_first(current_user, 5)
  end

  def leave
    @group = Group.find(params[:id])
    @group.remove_user_from_group(current_user)
    @group_members = @group.group_members_with_self_first(current_user, 5)
  end

  def unlead
    @group = Group.find(params[:id])
    current_user.leave_group_leadership(@group)
    @group_members = @group.group_members_with_self_first(current_user, 5)
  end

end
