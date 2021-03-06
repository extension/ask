# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class SelectdataController < ApplicationController
  skip_before_filter :verify_authenticity_token


  def groups
    @groups = Group.where("name like ?", "%#{params[:q]}%")
    token_hash = @groups.collect{|group| {id: group.id, text: group.name}}
    render(json: token_hash)
  end

  def locations
    @locations = Location.where("name like ?", "%#{params[:q]}%")
    token_hash = @locations.collect{|location| {id: location.id, text: location.name}}
    render(json: token_hash)
  end

  def counties
    @counties = County.includes(:location).where("name like ?", "%#{params[:q]}%")
    token_hash = @counties.collect{|county| {id: county.id, text: "#{county.name}, #{county.location.abbreviation}"}}
    render(json: token_hash)
  end

  def tags
    @tags = Tag.used_at_least_once.where("name like ?", "#{params[:q]}%")
    token_hash = @tags.collect{|tags| {id: tags.id, text: tags.name}}
    render(json: token_hash)
  end

  def experts
    if(Settings.elasticsearch_enabled)
      @experts = UsersIndex.available.name_or_login_search(params[:q]).order(last_activity_at: :desc).load
    else
      @experts = User.not_unavailable.pattern_search(params[:q]).order(last_activity_at: :desc)
    end
    token_hash = @experts.collect{|expert| {id: expert.id, text: expert.name}}
    render(json: token_hash)
  end

end
