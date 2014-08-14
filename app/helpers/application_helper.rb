# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

module ApplicationHelper
  
  def format_text_for_display(content)
    if content
      content = content.gsub(/[[:space:]]/, ' ')
    end
    return simple_format(content)
  end

  def humane_date(time)
     if(time.blank?)
       ''
     else
       time.strftime("%B %e, %Y, %l:%M %p %Z")
     end
  end

  def build_url_based_on_pref_filters(question_status)
    if current_user.filter_preference
      if question_status == "unanswered"
        return (link_to "Needs an Answer", expert_questions_path({status: "unanswered"}.merge(get_question_filter_params(current_user.filter_preference.setting[:question_filter]))))
      else
        return (link_to "Answered", expert_questions_path({status: "answered"}.merge(get_question_filter_params(current_user.filter_preference.setting[:question_filter]))))
      end
    else
      if question_status == "unanswered"
        return (link_to "Needs an Answer", expert_questions_path({status: "unanswered"}))
      else
        return (link_to "Answered", expert_questions_path({status: "answered"}))
      end
    end
  end
  
  def get_last_active_time(user)
    if user.last_active_at.present?
      if user.last_active_at.to_s == Date.today.to_s
        return 'today'
      else
        return time_ago_in_words(user.last_active_at) + ' ago'
      end
    else
      return 'No activity to date'
    end
  end
  
  def flash_notifications
    message = flash[:error] || flash[:notice] || flash[:warning] || flash[:success]
    return_string = ''
    if message
      type = flash.keys[0].to_s
      return_string << '<div id="flash_notification" class="' + type + '"><p>' + message + '</p></div>'
      return return_string.html_safe
    end
  end

  # http://blog.macromates.com/2006/wrapping-text-with-regular-expressions/
  def wrap_text(txt, col=120)
    txt.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/,
      "\\1\\3\n")
  end

  def link_public_user(user)
    return link_to(user.public_name, user_path(user.id), {:title => user.public_name, :rel => "author"}).html_safe
  end

  def expert_user(user)
    return user.name + raw(user.is_question_wrangler? ? ' <i class="icon-qw"></i>' : '') + raw(user.away ? ' <span class="on_vacation">(Not available)</span>' : '')
  end

  def link_expert_user(user)
    return link_to(user.name, expert_user_url(user.id), {:title => user.name, :class => (user.away ? "on_vacation" : "")}).html_safe + raw(user.is_question_wrangler? ? ' <i class="icon-qw"></i>' : '') + raw(user.away ? ' <span class="on_vacation">(Not available)</span>' : '')
  end
  
  def link_expert_group(group)
    return link_to(group.name, expert_group_url(group.id), {:title => group.name}).html_safe
  end

  def link_public_user_avatar(user, image_size = :medium)
    return link_to(get_avatar_for_user(user, image_size, false), user_path(user.id), {:title => user.public_name, :rel => "author", :class => "#{image_size}"}).html_safe
  end

  def link_expert_user_avatar(user, image_size = :medium, highlight_badge = false)
    return link_to(get_avatar_for_user(user, image_size), expert_user_path(user.id), {:title => user.name, :class => "#{image_size} " + (highlight_badge ? "highlight" : "")}).html_safe
  end

  def link_public_group_avatar(group, image_size = :medium)
    return link_to(get_avatar_for_group(group, image_size, false, false), group_path(group.id), {:title => group.name}).html_safe
  end

  def link_expert_group_avatar(group, image_size = :medium, suppress_single = false)
    return link_to(get_avatar_for_group(group, image_size), expert_group_url(group.id), {:title => group.name, :class => "#{image_size} " + (suppress_single ? "suppress" : "suppress")}).html_safe
  end
  
  def link_expert_group_avatar_group_label(group, image_size = :medium, suppress_single = false)
    return link_to(get_avatar_for_group(group, image_size, group_label = true), expert_group_url(group.id), {:title => group.name, :class => "#{image_size} " + (suppress_single ? "suppress_single" : "")}).html_safe
  end

  def get_avatar_for_group(group, image_size = :medium, group_label = false, show_badge = true)
    case image_size
        when :medium    then image_size_in_px = "100x100"
        when :thumb     then image_size_in_px = "40x40"
        when :mini     then image_size_in_px = "20x20"
    end
    
    group_label = group_label ? raw("<span class=\"group_label\">Group</span>") : ""
    show_badge = show_badge ? (group.open_questions.length > 0 ? raw("<span class=\"badge count_#{group.open_questions.length}\">#{group.open_questions.length}</span>") : "") : ""

    if group.avatar.present?
      return_string = raw("<span class=\"avatar_with_badge\">") + image_tag(group.avatar.url(image_size), :size => image_size_in_px, :class => "#{image_size}" ) + group_label + show_badge + raw("</span>")
    else
      # if no avatar, assign a random image
      return_string =  raw("<span class=\"avatar_with_badge\">") + image_tag("group_avatar_placeholder_0#{(group.id % Settings.group_avatar_count) + 1}.png", :size => image_size_in_px, :class => "#{image_size}") + group_label + show_badge + raw("</span>")
    end
    return return_string
  end

  def get_avatar_for_user(user, image_size = :medium, show_badge = true)
    case image_size
        when :medium    then image_size_in_px = "100x100"
        when :thumb     then image_size_in_px = "40x40"
        when :mini      then image_size_in_px = "20x20"
    end
    
    show_badge = show_badge ? (user.open_questions.length > 0 ? raw("<span class=\"badge count_#{user.open_questions.length}\">#{user.open_questions.length}</span>") : "") : ""
    
    if user.avatar.present?
      return_string = raw("<span class=\"avatar_with_badge\">") + image_tag(user.avatar.url(image_size), :size => image_size_in_px, :class => "#{image_size}") + show_badge + raw("</span>")
    else
      # if no avatar, assign a random image
      return_string = raw("<span class=\"avatar_with_badge\">") + image_tag("avatar_placeholder_0#{(user.id % Settings.user_avatar_count) + 1}.png", :size => image_size_in_px, :class => "#{image_size}") + show_badge + raw("</span>")
    end

    return return_string
  end
  
  def navtab(tabtext,whereto)
    if current_page?(whereto)
      "<li class='active'>#{link_to(tabtext,whereto)}</li>".html_safe
    else
      "<li>#{link_to(tabtext,whereto)}</li>".html_safe
    end
  end
  
  def profile_changes(changes)
    return_text_lines = []
    changes.each do |attribute,values|
      changed_from = values[0]
      changed_to = values[1]
      case attribute
      when 'position_id'
        display_attribute = 'position'
        display_from = blank_or_value(changed_from,'Position')
        display_to = blank_or_value(changed_to,'Position')
      when 'county_id'
        display_attribute = 'county'
        display_from = blank_or_value(changed_from,'County')
        display_to = blank_or_value(changed_to,'County')
      when 'location_id'
        display_attribute = 'location'
        display_from = blank_or_value(changed_from,'Location')
        display_to = blank_or_value(changed_to,'Location')        
      when 'institution_id'
        display_attribute = 'institution'
        display_from = blank_or_value(changed_from,'Community')
        display_to = blank_or_value(changed_to,'Community')
      else
        display_attribute = attribute
        display_from = blank_or_value(changed_from)
        display_to = blank_or_value(changed_to)        
      end

      return_text_lines << "#{display_attribute} changed from \"#{display_from}\" to \"#{display_to}\""
    end
    return_text_lines
  end
  
  def blank_or_value(value)
    if(value.blank?)
      '(blank)'
    else
      value
    end
  end
  private 
  
  def get_question_filter_params(question_filter_settings)
    return_params = Hash.new
    
    question_filter_settings.each do |key, value|
      case key
        when :groups
          return_params.merge!({group_id: value.first}) if value.present?
        when :locations
          return_params.merge!({location_id: value.first}) if value.present? 
        when :counties
          return_params.merge!({county_id: value.first}) if value.present?
        when :tags
          return_params.merge!({tag_id: value.first}) if value.present?
        when :privacy
          return_params.merge!({privacy: value.first}) if value.present?
        when :status
          # return_params.merge!({status: value.first}) if value.present?
      end
    end
    
    return return_params
  end
  
end
