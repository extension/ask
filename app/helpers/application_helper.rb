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

  # http://blog.macromates.com/2006/wrapping-text-with-regular-expressions/
  def wrap_text(txt, col=120)
    txt.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/,
      "\\1\\3\n")
  end

  def link_public_user(user)
    return link_to(user.name, user_path(user.id), {:title => user.name}).html_safe
  end

  def expert_user(user)
    return user.name + raw(user.is_question_wrangler? ? ' <i class="icon-qw"></i>' : '') + raw(user.away ? ' <span class="on_vacation">(Not available)</span>' : '')
  end

  def link_expert_user(user)
    return link_to(user.name, expert_user_path(user.id), {:title => user.name, :class => (user.away ? "on_vacation" : "")}).html_safe + raw(user.is_question_wrangler? ? ' <i class="icon-qw"></i>' : '') + raw(user.away ? ' <span class="on_vacation">(Not available)</span>' : '')
  end

  def link_public_user_avatar(user, image_size = :medium)
    return link_to(get_avatar_for_user(user, image_size), user_path(user.id), {:title => user.name}).html_safe
  end

  def link_expert_user_avatar(user, image_size = :medium)
    return link_to(get_avatar_for_user(user, image_size), expert_user_path(user.id), {:title => user.name}).html_safe
  end

  def link_public_group_avatar(group, image_size = :medium)
    return link_to(get_avatar_for_group(group, image_size), group_path(group.id), {:title => group.name}).html_safe
  end

  def link_expert_group_avatar(group, image_size = :medium)
    return link_to(get_avatar_for_group(group, image_size), expert_group_path(group.id), {:title => group.name}).html_safe
  end

  def get_avatar_for_group(group, image_size = :medium)
    case image_size
        when :medium    then image_size_in_px = "100x100"
        when :thumb     then image_size_in_px = "40x40"
        when :mini     then image_size_in_px = "20x20"
    end

    if group.avatar.present?
      return_string = image_tag(group.avatar.url(image_size))
    else
      # if no avatar, assign a random image
      return_string = image_tag("group_avatar_placeholder_0#{(group.id % Settings.group_avatar_count) + 1}.png", :size => image_size_in_px)
    end
    return return_string
  end

  def get_avatar_for_user(user, image_size = :medium)
    case image_size
        when :medium    then image_size_in_px = "100x100"
        when :thumb     then image_size_in_px = "40x40"
        when :mini      then image_size_in_px = "20x20"
    end

    if user.avatar.present?
      return_string = image_tag(user.avatar.url(image_size), :size => image_size_in_px)
    else
      # if no avatar, assign a random image
      return_string = raw("<span class=\"avatar_with_badge\">") + image_tag("avatar_placeholder_0#{(user.id % Settings.user_avatar_count) + 1}.png", :size => image_size_in_px) + (user.open_questions.length > 0 ? raw("<span class=\"badge\">#{user.open_questions.length}</span>") : "") + raw("</span>")
    end

    return return_string
  end

end
