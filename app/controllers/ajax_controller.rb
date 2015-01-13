# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AjaxController < ApplicationController
  include ActionView::Helpers::NumberHelper
  def tags
    if params[:term]
      search_term = Tag.normalizename(params[:term])
      tags = Tag.used_at_least_once.where("name like ?", "%#{search_term}%").limit(12)
    else
      tags = Tag.used_at_least_once.order('created_at DESC').limit(12)
    end
    list = []
    tags.each do |t|
      list <<  Hash[ id: t.id, label: t.name, name: t.name, tag_count: "#{number_with_delimiter(t.tag_count, :delimiter => ',')}"] if t.name != search_term
    end

    tag_count_description = "not used yet"

    param_tag = Tag.used_at_least_once.find_by_name(search_term)
    if param_tag
      tag_count_description = number_with_delimiter(param_tag.tag_count, :delimiter => ',')
    end

    list.unshift(Hash[id: nil, label: search_term, name: search_term, tag_count: tag_count_description])
    render json: list
  end


  def assignment_list_markup(expert_or_group)
      results = Hash.new
      results["id"] = expert_or_group.id
      results["class_type"] = expert_or_group.class.name
      results["availability"] = "available"

      if expert_or_group.class.name == "User"
        title = expert_or_group.title.present? ? "<br />#{expert_or_group.title}"  : ""
        county = expert_or_group.county.present? ? "#{expert_or_group.county.name}, " : ""
        location = expert_or_group.location.present? ? expert_or_group.location.name : ""
        name = expert_or_group.name
        if expert_or_group.available?
          availability = "available"
        elsif expert_or_group.away?
          availability = "not_available"
          name += " (away)"
          results["availability"] = "not_available" 
        else
          availability = "not_available"
          name += " (account is retired)"
          results["availability"] = "not_available"
        end
        results["markup_block"] = "<a class='#{availability}'>#{view_context.get_avatar_for_user(expert_or_group, :thumb).html_safe} #{name} #{title} #{county} #{location}</a>"
      else
        results["markup_block"] = "<a class='available'>#{view_context.get_avatar_for_group(expert_or_group, :thumb, true).html_safe} #{expert_or_group.name}</a>"
      end
      return results
  end

  def experts
    if params[:term]
      search_term = params[:term]

      groups_starting_with = Group.where(group_active: true).pattern_search(params[:term], "prefix").limit(9)
      groups_including = Group.where(group_active: true).pattern_search(params[:term]).limit(9)
      groups = (groups_starting_with + groups_including).uniq.take(9)

      experts_starting_with = User.exid_holder.not_blocked.pattern_search(params[:term], "prefix").limit(18 - groups.length)
      experts_including = User.exid_holder.not_blocked.pattern_search(params[:term]).limit(18 - groups.length)
      experts = (experts_starting_with + experts_including).uniq.take(9)
    else
      groups = Group.where(group_active: true).order('created_at DESC').limit(6)
      experts = User.exid_holder.active.not_blocked.order('created_at DESC').limit(6)
    end

    combined_array = groups + experts

    list = combined_array.map{|expert_or_group| assignment_list_markup(expert_or_group)}
    render json: list
  end

  def groups
    if params[:term]
      search_term = params[:term]

      groups_starting_with = Group.where(group_active: true).pattern_search(params[:term], "prefix").limit(12)
      groups_including = Group.where(group_active: true).pattern_search(params[:term]).limit(12)
      groups = (groups_starting_with + groups_including).uniq.take(12)
    else
      groups = Group.where(group_active: true).order('created_at DESC').limit(12)
    end
    list = groups.map {|g| Hash[ id: g.id, label: g.name, name: g.name]}
    render json: list
  end

  def counties
    if params[:term]
      like= "%".concat(params[:term].concat("%"))
      counties = County.where("name like ?", like).where(:location_id => params[:location_id])
    else
      counties = County.where(:location_id => params[:location_id])
    end
    list = counties.map {|c| Hash[ id: c.id, label: c.name, name: c.name]}
    render json: list
  end


  def show_location
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    location = Location.find(params[:requested_location])
    render :partial => 'show_location', :locals => {:location => location}
  end


  def edit_location
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    location = Location.find(params[:requested_location])
    render :partial => 'ajax/edit_location', :locals => {:location => location}
  end


  def add_county
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    @county = County.find(params[:requested_county])
    all_county = @county.location.get_all_county

    # if they're selecting a specific county, then take away the 'all county' selection
    if @object.expertise_counties.include?(all_county)
      @object.expertise_counties.delete(all_county)
    end

    if !@object.expertise_counties.include?(@county)
      @object.expertise_counties << @county
      if !@object.expertise_locations.include?(@county.location)
        @object.expertise_locations << @county.location
      end
      @object.save
    end

    change_hash = Hash.new
    change_hash[:expertise_locations] = {:old => "", :new => @county.name}
    UserEvent.log_added_county(@object, current_user, change_hash)
  end


  def add_location
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    location = Location.find_by_id(params[:requested_location])
    @object.expertise_counties.where("location_id = ?", location.id).each do |c|
      @object.expertise_counties.delete(c)
    end

    # when adding location, start out with the all county selection
    @object.expertise_counties << location.get_all_county unless @object.expertise_counties.include?(location.get_all_county)

    if !@object.expertise_locations.include?(location)
      @object.expertise_locations << location
    end

    change_hash = Hash.new
    change_hash[:expertise_locations] = {:old => "", :new => location.name}
    UserEvent.log_added_location(@object, current_user, change_hash)
  end


  def remove_location
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    location = Location.find(params[:location_id])
    @object.expertise_counties.where("location_id = ?", params[:location_id]).each do |c|
      @object.expertise_counties.delete(c)
    end
    @object.expertise_locations.delete(location)

    change_hash = Hash.new
    change_hash[:expertise_locations] = {:old => location.name, :new => ""}
    UserEvent.log_removed_location(@object, current_user, change_hash)
  end


  def remove_county
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    county = County.find(params[:county_id])
    location = county.location
    @object.expertise_counties.delete(county)
    # if they just removed the last county from this location, add the all county county to it
    if @object.expertise_counties.where("counties.location_id = ?", location.id).count == 0
      @object.expertise_counties << location.get_all_county
    end

    change_hash = Hash.new
    change_hash[:expertise_locations] = {:old => county.name, :new => ""}
    UserEvent.log_removed_county(@object, current_user, change_hash)
  end

end
