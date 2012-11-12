module QuestionsHelper
  def stringify_question_event(q_event)
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

    case q_event.event_state
    when QuestionEvent::ASSIGNED_TO 
      recipient_class = ""
      if q_event.recipient.is_question_wrangler?
        recipient_class = "class='qw'"
      end
      reassign_msg = "Assigned to <strong #{recipient_class}>#{link_to "#{q_event.recipient.name}", expert_user_path(q_event.recipient.id)}</strong> by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
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
      return "No answer available was sent from <strong #{qw}>#{initiator_full_name}</strong><span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::CLOSED
      close_msg = "Question Closed Out by <strong #{qw}>#{initiator_full_name}</strong><span> #{humane_date(q_event.created_at)}</span>"
      close_msg += " <span class=\"comment\">#{q_event.response}</span>"
      return close_msg.html_safe
    when QuestionEvent::REJECTED
      reject_msg = "Question Rejected by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      reject_msg = reject_msg + " <span class=\"reject comment\">#{q_event.response}</span>"
      return reject_msg.html_safe
    when QuestionEvent::REACTIVATE
      return "Question Reactivated by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    # when QuestionEvent::RECATEGORIZED
    #       message = "Question Recategorized by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
    #       message += "<span>Category changed to #{q_event.category}"
    #       if(!q_event.previous_category.blank? and q_event.previous_category != 'unknown')
    #          message += " from #{q_event.previous_category}"
    #       end
    #       message += "</span>"
    #       return message
    when QuestionEvent::WORKING_ON
      return "Question worked on by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::EDIT_QUESTION
      return "Question edited by <strong>Submitter</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::REOPEN
      return "Question reopened by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::CLOSED
      return "Question closed by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::PUBLIC_RESPONSE
      return "Comment posted by <strong>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    when QuestionEvent::COMMENT 
      comment_msg = "Comment posted by <strong #{qw}>#{initiator_full_name}</strong> <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>"
      comment_msg = comment_msg + " <div class='comment_icon'>#{format_text_for_display(q_event.response)}</div>" if q_event.response
      return comment_msg.html_safe
    else
      return "Question #{q_event.question.id.to_s} #{QuestionEvent::EVENT_TO_TEXT_MAPPING[q_event.event_state] ||= nil} #{((q_event.recipient) ? q_event.recipient.name : '')} by #{initiator_full_name} <span>#{time_ago_in_words(q_event.created_at)} ago</span> <small>#{humane_date(q_event.created_at)}</small>".html_safe
    end
  end
  
end
