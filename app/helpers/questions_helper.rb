module QuestionsHelper

  def stringify_question_event(q_event, show_question_id=false)
    if q_event.initiator.present? && (q_event.initiator.id == User.system_user_id)
      initiator_full_name = "System"
    elsif q_event.initiator
      initiator_full_name = link_to q_event.initiator.name, expert_user_path(q_event.initiator.id)
      if q_event.initiator.is_question_wrangler?
        qw = "class='qw'"
      end
    else
      initiator_full_name = "anonymous"
    end

    question_context = (show_question_id ? link_to('#'+q_event.question.id.to_s, expert_question_path(:id => q_event.question.id)) : "Question")

    case q_event.event_state
    when QuestionEvent::PASSED_TO_WRANGLER
      recipient_class = ""
      if q_event.recipient.is_question_wrangler?
        recipient_class = "class='qw'"
      end
      comment = " <span class=\"comment\">#{q_event.response}</span>" if q_event.response
      reassign_msg = "<strong #{qw}>#{initiator_full_name}</strong> handed off to a Question Wrangler #{comment} <strong>System</strong> assigned to <strong #{recipient_class}>#{link_to "#{q_event.recipient.name}", expert_user_path(q_event.recipient.id)}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      return reassign_msg.html_safe
    when QuestionEvent::ASSIGNED_TO
      recipient_class = ""
      if q_event.recipient.is_question_wrangler?
        recipient_class = "class='qw'"
      end
      reassign_msg = "<strong #{qw}>#{initiator_full_name}</strong> assigned to <strong #{recipient_class}>#{link_to "#{q_event.recipient.name}", expert_user_path(q_event.recipient.id)}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      reassign_msg = reassign_msg + " <span class=\"comment\">#{q_event.response}</span>" if q_event.response
      return reassign_msg.html_safe
    when QuestionEvent::ASSIGNED_TO_GROUP
      reassign_msg = "Assigned to group <strong>#{link_to "#{q_event.assigned_group.name}", expert_group_path(q_event.assigned_group.id)}</strong> by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      reassign_msg = reassign_msg + " <span class=\"comment\">#{q_event.response}</span>" if q_event.response
      return reassign_msg.html_safe
    when QuestionEvent::CHANGED_GROUP
      previous_group_link = link_to(q_event.previous_group.name, expert_group_path(q_event.previous_group))
      changed_group_link = link_to(q_event.changed_group.name, expert_group_path(q_event.changed_group))
      msg = "Group changed from <strong>#{previous_group_link}</strong> to <strong>#{changed_group_link}</strong> by <strong #{qw}>#{initiator_full_name}</strong>"
      msg += " <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      return msg.html_safe
    when QuestionEvent::RESOLVED
      return "Resolved by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::NO_ANSWER
      return "#{question_context} response \"No answer available\" was sent from <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::CLOSED
      close_msg = "Question Closed Out by <strong #{qw}>#{initiator_full_name}</strong><span> #{humane_date(q_event.created_at)}</span>"
      close_msg += " <span class=\"comment\">#{q_event.response}</span>"
      return close_msg.html_safe
    when QuestionEvent::REJECTED
      reject_msg = "#{question_context} Rejected by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      reject_msg = reject_msg + " <span class=\"reject comment\">#{q_event.response}</span>"
      return reject_msg.html_safe
    when QuestionEvent::REACTIVATE
      return "Question Reactivated by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::TAG_CHANGE
      new_tags = q_event.tags.split(", ").collect{ |t| content_tag(:span, t, :class => "tag tag-topic")}.join(", ").html_safe
      previous_tags = q_event.previous_tags.split(", ").collect{ |t| content_tag(:span, t, :class => "tag tag-topic")}.join(", ").html_safe
      message = "Tags edited by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      message += "<span class=\"history_of_tags\">Changed to #{new_tags}"
      if(!q_event.previous_tags.blank? && q_event.previous_tags != 'unknown')
        message += " from #{previous_tags}"
      end
      message += "</span>"
      return message.html_safe
    when QuestionEvent::ADDED_TAG
      message = "<strong #{qw}>#{initiator_full_name}</strong> added <span class='label-small-topic'>#{q_event.changed_tag}</span> <span >#{time_ago_in_words(q_event.created_at)} ago</span> <small>- #{humane_date(q_event.created_at)}</small>"
      return message.html_safe
    when QuestionEvent::DELETED_TAG
      message = "<strong #{qw}>#{initiator_full_name}</strong> <span class='label-deleted'>removed</span> <span class='label-small-topic'>#{q_event.changed_tag}</span> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>- #{humane_date(q_event.created_at)}</small>"
      return message.html_safe
    when QuestionEvent::CHANGED_LOCATION
      old_county = "<span class=\"tag tag-geography\">#{q_event.updated_question_values[:changed_county][:old].strip == '' ? 'All Counties' : q_event.updated_question_values[:changed_county][:old]}</span>"
      old_location = "<span class=\"tag tag-geography\">#{q_event.updated_question_values[:changed_location][:old].strip == '' ? 'No Location' : q_event.updated_question_values[:changed_location][:old]}</span>"
      new_county = "<span class=\"tag tag-geography\">#{q_event.updated_question_values[:changed_county][:new].strip == '' ? 'All Counties' : q_event.updated_question_values[:changed_county][:new]}</span>"
      new_location = "<span class=\"tag tag-geography\">#{q_event.updated_question_values[:changed_location][:new].strip == '' ? 'No Location' : q_event.updated_question_values[:changed_location][:new]}</span>"

      message = "Location edited by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      message += "<span class=\"history_of_tags\">Changed from "

      if q_event.updated_question_values[:changed_location][:old] == ''
        old_location = "<span class=\"tag tag-geography\">No Location</span>"
        old_county = ""
      end

      if q_event.updated_question_values[:changed_location][:new] == ''
        new_location = "<span class=\"tag tag-geography\">No Location</span>"
        new_county = ""
      end

      message += "#{old_county} #{old_location} to #{new_county} #{new_location}"
      message += "</span>"
      return message.html_safe
    when QuestionEvent::CHANGED_FEATURED
      return "#{question_context} featured changed from #{q_event.updated_question_values[:old_value]} to #{q_event.updated_question_values[:new_value]} by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::WORKING_ON
      return "#{question_context} worked on by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::EDIT_QUESTION
      return "#{question_context} edited by <strong>Submitter</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::EXPERT_EDIT_QUESTION
      return "#{question_context} edited by expert <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small> see #{link_to 'revision history', history_expert_question_path(q_event.question) } for more information".html_safe
    when QuestionEvent::EXPERT_EDIT_RESPONSE
      return "#{question_context} response edited by expert <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>. See #{link_to('response history', response_history_expert_question_path(:id => q_event.question.id, :response_id => q_event.additional_data.strip))} page".html_safe
    when QuestionEvent::REOPEN
      return "#{question_context} reopened by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::CLOSED
      return "#{question_context} closed by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::PUBLIC_RESPONSE
      return "#{question_context} Comment posted by <strong>Submitter</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::CHANGED_TO_PUBLIC
      return "#{question_context} made public by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::CHANGED_TO_PRIVATE
      return "#{question_context} made private by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::INTERNAL_COMMENT
      comment_msg = "Note posted by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      comment_msg = comment_msg + " <span class=\"comment\">#{format_text_for_display(q_event.response)}</span>" if q_event.response
      return comment_msg.html_safe
    else
      return "Question #{q_event.question.id.to_s} #{QuestionEvent::EVENT_TO_TEXT_MAPPING[q_event.event_state] ||= nil} #{((q_event.recipient) ? q_event.recipient.name : '')} by #{initiator_full_name} <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    end
  end

end
