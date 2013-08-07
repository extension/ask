# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::GroupsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
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
    @group = Group.find_by_id(params[:id])
    @group_members = @group.joined
    respond_to do |format|
      format.csv { send_data User.to_csv(@group_members, ["first_name", "last_name", "email"]), :filename => "#{@group.name.gsub(' ', '_')}_Member_Emails.csv" }
    end
  end
  
  def about
    @group = Group.find_by_id(params[:id])
    if !@group 
      return record_not_found
    end
    @group_members = @group.joined.order('connection_type ASC').order("users.last_active_at DESC")
    @group_members_route_from_anywhere = @group.joined.route_from_anywhere
  end
  
  def leaders
    @group = Group.find_by_id(params[:id])
    if !@group 
      return record_not_found
    end
    @group_members = @group.joined.order('connection_type ASC').order("users.last_active_at DESC")
    @group_members_route_from_anywhere = @group.joined.route_from_anywhere
  end
  
  def show
    @group = Group.find_by_id(params[:id])
    if !@group 
      return record_not_found
    end
    
    @question_list = "Needs an Answer"
    @questions = @group.open_questions.page(params[:page]).order('created_at DESC')
    @question_count = @group.open_questions.length
    @group_members = @group.group_members_with_self_first(current_user, 5)
    @group_tags = @group.tags.limit(7).order('updated_at DESC')
  end
  
  def answered
    @group = Group.find_by_id(params[:id])
    if !@group 
      return record_not_found
    end
    @question_list = "Answered"
    @questions = @group.answered_questions.page(params[:page]).order('resolved_at DESC')
    @question_count = @group.answered_questions.length
    @group_members = @group.group_members_with_self_first(current_user, 5)
    @group_tags = @group.tags.limit(7).order('updated_at DESC')
    render :action => 'show'
  end
  
  def members
    @group = Group.find_by_id(params[:id])
    if !@group 
      return record_not_found
    end
    @group_members = @group.joined.order('connection_type ASC').order("users.last_active_at DESC")
    @handling_rates = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @group_members.map(&:id)})
  end
  
  def questions_by_tag
    @group = Group.find_by_id(params[:group_id])
    @tag = Tag.find_by_id(params[:tag_id])
    
    return record_not_found if (!@group || !@tag)
    
    @questions = Question.from_group(@group.id).tagged_with(@tag.id).not_rejected.order("questions.status_state ASC").limit(25)
  end  
  
  def profile
    @group = Group.find_by_id(params[:id])
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
        # if the group is marked inactive, then the group's widget gets marked as inactive
        else
          if @group.widget_active == true 
            @group.widget_active = false
            change_hash[:widget_active] = {:old => true, :new => false}
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
    @group = Group.find_by_id(params[:id])
    @locations = Location.order('fipsid ASC')
    @object = @group
  end
  
  def tags
    @group = Group.find_by_id(params[:id])
    @group_tags = @group.tags.order('name ASC')
  end
  
  def add_tag
    @group = Group.find_by_id(params[:id])
    @tag = @group.set_tag(params[:tag])
    if @tag == false
      render :nothing => true
    end
  end
  
  def remove_tag
    @group = Group.find_by_id(params[:id])
    tag = Tag.find(params[:tag_id])
    @group.tags.delete(tag)
  end
  
  
  def assignment_options
    @group = Group.find_by_id(params[:id])
    if request.put?
      change_hash = Hash.new
      @group.attributes = params[:group]
      
      if @group.assignment_outside_locations_changed? 
        change_hash[:assignment_outside_locations] = {:old => @group.assignment_outside_locations_was.to_s, :new => @group.assignment_outside_locations.to_s}
        # if they do not want questions outside their locations and the show location setting is false for widgets (ie. they get sent to question wranglers), 
        # then set the location option to true.
        if @group.assignment_outside_locations == false && @group.widget_show_location == false
          @group.widget_show_location = true
          change_hash[:show_location] = {:old => false, :new => true}
        end
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
    @group = Group.find_by_id(params[:id])
    if request.put?
      @group.attributes = params[:group]
      change_hash = Hash.new
      
      if @group.widget_active_changed? 
        if @group.widget_active == true && @group.group_active == false
          @group.widget_active = false
          flash[:error] = "This group is not active. You will need to activate the group on the group edit page before the widget can be activated."
          return render nil
        end
        change_hash[:widget_active] = {:old => @group.widget_active_was.to_s, :new => @group.widget_active.to_s}
      end
      
      if @group.widget_public_option_changed? 
        change_hash[:public_option] = {:old => @group.widget_public_option_was.to_s, :new => @group.widget_public_option.to_s}
      end
      
      if @group.widget_upload_capable_changed? 
        change_hash[:upload_capable] = {:old => @group.widget_upload_capable_was.to_s, :new => @group.widget_upload_capable.to_s}
      end
      
      if @group.widget_show_location_changed? 
        if @group.widget_show_location == false && @group.assignment_outside_locations == false
          flash[:error] = 'You have to show the location fields on your widgets as long as you are not accepting questions outside your location. That setting can be changed in your group assignment options preferences'
          return redirect_to(expert_group_widget_path)
        end
        
        change_hash[:show_location] = {:old => @group.widget_show_location_was.to_s, :new => @group.widget_show_location.to_s}
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
    @group = Group.find_by_id(params[:id])
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
      current_user.log_create_group(@group)
      redirect_to(expert_group_path(@group.id), :notice => 'Group was successfully created.')
    else
      render :action => 'new'
    end
  end
  
  def join
    @group = Group.find_by_id(params[:id])
    current_user.join_group(@group,"member")
    @group_members = @group.group_members_with_self_first(current_user, 5)
  end
  
  def lead
    @group = Group.find_by_id(params[:id])
    current_user.join_group(@group,"leader")
    @group_members = @group.group_members_with_self_first(current_user, 5)
  end
  
  def leave
    @group = Group.find_by_id(params[:id])
    current_user.leave_group(@group, "member")
    @group_members = @group.group_members_with_self_first(current_user, 5)
    # when the last person leaves the group, deactivate the group's widget and the group itself
    if @group_members.count == 0
      change_hash = Hash.new
      if @group.group_active == true
        @group.update_attribute(:group_active, false)
        change_hash[:group_active] = {:old => true, :new => false}
      end
      
      if @group.widget_active == true
        @group.update_attribute(:widget_active, false)
        change_hash[:widget_active] = {:old => true, :new => false}
      end
      GroupEvent.log_edited_attributes(@group, User.system_user, nil, change_hash)
    end
    
    # remove this person's listview prefs for this group if it exists
    pref = current_user.filter_preference
    if pref.present? && pref.setting[:question_filter][:groups].present? && pref.setting[:question_filter][:groups][0].to_i == @group.id
      pref.setting[:question_filter].merge!({:groups => nil})
      pref.save
    end
  end
  
  def unlead
    @group = Group.find_by_id(params[:id])
    current_user.leave_group_leadership(@group, "leader")
    @group_members = @group.group_members_with_self_first(current_user, 5)
  end
  
end