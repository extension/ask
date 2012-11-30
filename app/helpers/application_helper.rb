# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

module ApplicationHelper
  # TODO: Need to fix this
  def format_text_for_display(content)
    #return word_wrap(simple_format(auto_link(content, :all, :target => "_blank")))
    return simple_format(content)
  end

  def humane_date(time)
     if(time.blank?)
       ''
     else
       time.strftime("%B %e, %Y, %l:%M %p %Z")
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
    return link_to(user.public_name, user_path(user.id), {:title => user.public_name}).html_safe
  end

  def expert_user(user)
    return user.name + raw(user.is_question_wrangler? ? ' <i class="icon-qw"></i>' : '') + raw(user.away ? ' <span class="on_vacation">(Not available)</span>' : '')
  end

  def link_expert_user(user)
    return link_to(user.name, expert_user_path(user.id), {:title => user.name, :class => (user.away ? "on_vacation" : "")}).html_safe + raw(user.is_question_wrangler? ? ' <i class="icon-qw"></i>' : '') + raw(user.away ? ' <span class="on_vacation">(Not available)</span>' : '')
  end
  
  def link_expert_group(group)
    return link_to(group.name, expert_group_path(group.id), {:title => group.name}).html_safe
  end

  def link_public_user_avatar(user, image_size = :medium)
    return link_to(get_avatar_for_user(user, image_size, false), user_path(user.id), {:title => user.public_name}).html_safe
  end

  def link_expert_user_avatar(user, image_size = :medium, suppress_single = false)
    return link_to(get_avatar_for_user(user, image_size), expert_user_path(user.id), {:title => user.name, :class => "#{image_size} " + (suppress_single ? "suppress_single" : "")}).html_safe
  end

  def link_public_group_avatar(group, image_size = :medium)
    return link_to(get_avatar_for_group(group, image_size, false, false), group_path(group.id), {:title => group.name}).html_safe
  end

  def link_expert_group_avatar(group, image_size = :medium, suppress_single = false)
    return link_to(get_avatar_for_group(group, image_size), expert_group_url(group.id), {:title => group.name, :class => "#{image_size} " + (suppress_single ? "suppress_single" : "")}).html_safe
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
      return_string = raw("<span class=\"avatar_with_badge\">") + image_tag(group.avatar.url(image_size), :size => image_size_in_px) + group_label + show_badge + raw("</span>")
    else
      # if no avatar, assign a random image
      return_string =  raw("<span class=\"avatar_with_badge\">") + image_tag("group_avatar_placeholder_0#{(group.id % Settings.group_avatar_count) + 1}.png", :size => image_size_in_px) + group_label + show_badge + raw("</span>")
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
      return_string = raw("<span class=\"avatar_with_badge\">") + image_tag(user.avatar.url(image_size), :size => image_size_in_px) + show_badge + raw("</span>")
    else
      # if no avatar, assign a random image
      return_string = raw("<span class=\"avatar_with_badge\">") + image_tag("avatar_placeholder_0#{(user.id % Settings.user_avatar_count) + 1}.png", :size => image_size_in_px) + show_badge + raw("</span>")
    end

    return return_string
  end

end
