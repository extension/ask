module QuestionsHelper
  def stringify_question_event(q_event)
    if q_event.initiator.id == User.systemuserid
      initiator_full_name = "System"
    elsif q_event.initiator
      initiator_full_name = link_to q_event.initiator.name, expert_user_path(q_event.initiator.id)
      if q_event.initiator.is_question_wrangler?
        qw = "class='qw'"
      end
    end

    case q_event.event_state
    when QuestionEvent::ASSIGNED_TO 
      recipient_class = ""
      if q_event.recipient.is_question_wrangler?
        recipient_class = "class='qw'"
      end
      reassign_msg = "Assigned to <strong #{recipient_class}>#{link_to "#{q_event.recipient.name}", expert_user_path(q_event.recipient.id)}</strong> by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>"
      reassign_msg = reassign_msg + " <span>Comments: #{q_event.response}</span>" if q_event.response
      return reassign_msg.html_safe
    when QuestionEvent::RESOLVED 
      return "Resolved by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::NO_ANSWER
      return "No answer available was sent from <strong #{qw}>#{initiator_full_name}</strong><span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::CLOSED
      close_msg = "Question Closed Out by <strong #{qw}>#{initiator_full_name}</strong><span> #{humane_date(q_event.created_at)}</span>"
      close_msg += " <span>Close Out Comments: #{q_event.response}</span>"
      return close_msg.html_safe
    when QuestionEvent::MARKED_SPAM
      return "Marked as spam by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::MARKED_NON_SPAM
      return "Marked as non-spam by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::REJECTED
      reject_msg = "Question Rejected by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>"
      reject_msg = reject_msg + " <span>Reject Comments: #{q_event.response}</span>"
      return reject_msg.html_safe
    when QuestionEvent::REACTIVATE
      return "Question Reactivated by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    # when QuestionEvent::RECATEGORIZED
    #       message = "Question Recategorized by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>"
    #       message += "<span>Category changed to #{q_event.category}"
    #       if(!q_event.previous_category.blank? and q_event.previous_category != 'unknown')
    #          message += " from #{q_event.previous_category}"
    #       end
    #       message += "</span>"
    #       return message
    when QuestionEvent::WORKING_ON
      return "Question worked on by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::EDIT_QUESTION
      return "Question edited by <strong>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::REOPEN
      return "Question reopened by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::CLOSED
      return "Question closed by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::PUBLIC_RESPONSE
      return "Comment posted by <strong>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>".html_safe
    when QuestionEvent::COMMENT 
      comment_msg = "Comment posted by <strong #{qw}>#{initiator_full_name}</strong> <span> #{humane_date(q_event.created_at)} </span>"
      comment_msg = comment_msg + " <div class='comment_icon'>#{format_text_for_display(q_event.response)}</div>" if q_event.response
      return comment_msg.html_safe
    else
      return "Question #{q_event.question.id.to_s} #{Question::EVENT_TO_TEXT_MAPPING[q_event.event_state] ||= nil} #{((q_event.recipient) ? q_event.recipient.name : '')} by #{initiator_full_name} <span> #{humane_date(q_event.created_at)} </span>".html_safe
    end
  end
  
end
