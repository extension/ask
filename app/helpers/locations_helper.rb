# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

module LocationsHelper

  def get_location_options
    locations = Location.find(:all, :order => 'entrytype, name')
    return [['', '']].concat(locations.map{|l| [l.name, l.id]})
  end

  def get_county_options(provided_location = nil)
    [['Entire state', '']] + get_county_options_without_all_counties(provided_location)
  end

  def get_county_options_without_all_counties(provided_location = nil)
    if params[:location_id] && params[:location_id].strip != '' && location = Location.find(params[:location_id])
      counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      counties.map{|c| [c.name, c.id]}
    elsif(provided_location)
      counties = provided_location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      counties.map{|c| [c.name, c.id]}
    end
  end


  def display_location_and_county
    locations = []
    locations  << current_county.name if current_county
    locations  << (current_location.nil? ? 'Unknown' : current_location.name)
    locations.join(', ').html_safe
  end

end