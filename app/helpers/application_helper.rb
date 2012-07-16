module ApplicationHelper
  # TODO: Need to fix this
  def format_text_for_display(content)
    #return word_wrap(simple_format(auto_link(content, :all, :target => "_blank"))) 
    return content
  end
  
  def humane_date(time)
     if(time.blank?)
       ''
     else
       time.strftime("%B %e, %Y, %l:%M %p %Z")
     end
  end
  
  def flash_notifications
    message = flash[:error] || flash[:notice] || flash[:warning]
    return_string = ''
    if message
      type = flash.keys[0].to_s
      return_string << '<div id="flash_notification" class="' + type + '"><p>' + message + '</p></div>'
      return return_string.html_safe
    end
  end
  
  def get_avatar(user, image_size = :medium)
    case image_size
        when :medium    then image_size_in_px = "100x100"
        when :thumb     then image_size_in_px = "50x50"
    end
    
    if user.avatar.present? 
      return_string = image_tag(user.avatar.url(image_size))
    # no avatar for user
    else
      return_string = image_tag("avatar_placeholder.png", :size => image_size_in_px)
    end
    
    return link_to(return_string, expert_user_path(user.id), {:title => user.name}).html_safe  
  end
  
  def default_location_id(fallback_location_id = nil)
    if(@personal[:location].blank?)
      if(fallback_location_id.blank?)
        return ''
      else
        return fallback_location_id
      end
    else
      return @personal[:location].id
    end
  end
  
  
  def default_county_id(fallback_county_id = nil)
    if(@personal[:county].blank?)
      if(fallback_county_id.blank?)
        return ''
      else
        return fallback_county_id
      end
    else
      return @personal[:county].id
    end
  end
  
  def get_location_options
    locations = Location.find(:all, :order => 'entrytype, name')
    return [['', '']].concat(locations.map{|l| [l.name, l.id]})
  end
  
  def get_county_options(provided_location = nil)
    if params[:location_id] and params[:location_id].strip != '' and location = Location.find(params[:location_id])
      counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      return ([['', '']].concat(counties.map{|c| [c.name, c.id]}))
    elsif(provided_location)
      counties = provided_location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      return ([['', '']].concat(counties.map{|c| [c.name, c.id]}))
    end
  end
  
end
