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
    @locations = Location.find(:all, :order => 'fipsid ASC')
  end
  
  
  def addlocation
    @location = Location.find(params[:requested_location])
    if !current_user.locations.include?(@location)
      current_user.locations << @location
      current_user.save
    end
  end
  
  def removelocation
    location = Location.find(params[:location_id])
    current_user.counties.where(location_id: location.id).destroy_all
    current_user.locations.delete(location)
  end
  
  def removecounty
    county = County.find(params[:county_id])
    current_user.counties.delete(county)
  end
  
  def addcounty
     @county = County.find(params[:requested_county])
     if !current_user.counties.include?(@county)
       current_user.counties << @county
       if !current_user.locations.include?(@county.location)
         current_user.locations << @county.location
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
