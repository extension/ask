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
  
  
  def get_user_name(id)
    return User.find(:first, :conditions => {:id => id}).name
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
  
end
