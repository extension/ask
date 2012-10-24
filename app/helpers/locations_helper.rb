# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

module LocationsHelper

  def default_location_id(fallback_location_id = nil)
    if(current_location.present?)
      current_location.id
    elsif(fallback_location_id.present?)
      fallback_location_id
    end
  end

  def default_county_id(fallback_county_id = nil)
    if(current_county.present?)
      current_county.id
    elsif(fallback_county_id.present?)
      fallback_county_id
    end
  end

  def get_location_options
    locations = Location.find(:all, :order => 'entrytype, name')
    return [['', '']].concat(locations.map{|l| [l.name, l.id]})
  end

  def get_county_options(provided_location = nil)
    if params[:location_id] and params[:location_id].strip != '' and location = Location.find(params[:location_id])
      counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      return ([['All counties', 'All counties']].concat(counties.map{|c| [c.name, c.id]}))
    elsif(provided_location)
      counties = provided_location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      return ([['All counties', 'All counties']].concat(counties.map{|c| [c.name, c.id]}))
    end
  end

  def display_location_and_county
    locations = []
    locations  << current_county.name if current_county
    locations  << (current_location.nil? ? 'Unknown' : current_location.name)
    locations.join(', ').html_safe
  end

end