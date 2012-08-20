# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::SettingsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def profile
    @user = current_user
    if request.put?
      @user.attributes = params[:user]
      
      if params[:delete_avatar] && params[:delete_avatar] == "1"
        @user.avatar = nil
      end
      
      if @user.save
        redirect_to(expert_settings_profile_path, :notice => 'Profile was successfully updated.')
      else
        render :action => 'profile'
      end
    end
  end
  
  def location
    @counties = ""
    @user = current_user
    @locations = Location.order('fipsid ASC')
  end
  
  def show_counties
    @location_id = params[:location_id]
    respond_to do |format|
      format.js
    end
  end
  
  def editlocation
    render :partial => 'location_edit'
  end
  
  def edit_location
    @location = Location.find(params[:requested_location])
    render :partial => 'edit_location', :locals => {:location => @location}
  end
  
  def show_location
    @location = Location.find(params[:requested_location])
    render :partial => 'show_location', :locals => {:location => @location}
  end
  
  def addlocation
    @location = Location.find(params[:requested_location])
    current_user.expertise_counties.where("location_id = ?", params[:requested_location]).each do |c|
      current_user.expertise_counties.delete(c)
    end
    if !current_user.expertise_locations.include?(@location)
      current_user.expertise_locations << @location
      current_user.save
    end
  end
  
  def removelocation
    location = Location.find(params[:location_id])
    current_user.expertise_counties.where("location_id = ?", params[:location_id]).each do |c|
      current_user.expertise_counties.delete(c)
    end
    current_user.expertise_locations.delete(location)
  end
  
  def removecounty
    county = County.find(params[:county_id])
    current_user.expertise_counties.delete(county)
  end
  
  def addcounty
     @county = County.find(params[:requested_county])
     if !current_user.expertise_counties.include?(@county)
       current_user.expertise_counties << @county
       if !current_user.expertise_locations.include?(@county.location)
         current_user.expertise_locations << @county.location
       end
       current_user.save
     end
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
  
end
