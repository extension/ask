# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Webmail::ExamplesController < ApplicationController
  skip_before_filter :set_yolo

  def group_user_join
    mail = GroupMailer.group_user_join(user: User.first, group: Group.last, new_member:User.first, cache_email: false)
    return render_mail(mail)
  end
  
  def group_user_left
    mail = GroupMailer.group_user_left(user: User.first, group: Group.last, former_member:User.first, cache_email: false)
    return render_mail(mail)
  end
  
  def group_leader_join
    mail = GroupMailer.group_leader_join(user: User.first, group: Group.last, new_leader:User.first, cache_email: false)
    return render_mail(mail)
  end
  
  def group_leader_left
    mail = GroupMailer.group_leader_left(user: User.first, group: Group.last, former_leader:User.first, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_assignment
    mail = InternalMailer.aae_assignment(user: User.first, question: Question.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_assignment_group
    mail = InternalMailer.aae_assignment_group(user: User.first, question: Question.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_reassignment
    mail = InternalMailer.aae_reassignment(user: User.first, question: Question.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_daily_summary
    mail = InternalMailer.aae_daily_summary(user: User.first, groups: [Group.first,Group.last,Group.find(Group::QUESTION_WRANGLER_GROUP_ID)], cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_public_edit
    mail = InternalMailer.aae_public_edit(user: User.first, question: Question.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_public_response
    mail = InternalMailer.aae_public_response(user: User.first, response: Response.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_internal_comment
    mail = InternalMailer.aae_internal_comment(user: User.first, question: Question.last, internal_comment_event: QuestionEvent.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_reject
    mail = InternalMailer.aae_reject(user: User.first, rejected_event: QuestionEvent.where(event_state:QuestionEvent::REJECTED).first, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_expert_tag_edit
    mail = InternalMailer.aae_expert_tag_edit(user: current_user, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_expert_vacation_edit
    mail = InternalMailer.aae_expert_vacation_edit(user: current_user, cache_email: false)
    return render_mail(mail)
  end
  
  def public_expert_response
    mail = PublicMailer.public_expert_response(user: User.first, question: Question.answered.last, expert: User.offset(rand(User.count)).first, cache_email: false)
    return render_mail(mail)
  end
  
  def public_submission_acknowledgement
    mail = PublicMailer.public_submission_acknowledgement(user: User.first, question: Question.last, cache_email: false)
    if(mail.multipart?)
      if(params[:view] == 'text')
        if(params[:wordwrap] == 'no')
          return(render_text_mail(get_text_part(mail),false))          
        else
          return(render_text_mail(get_text_part(mail)))
        end
      else
        return(render_mail(get_html_part(mail)))
      end
    else
      return render_mail(mail)
    end
  end
  
  def public_evaluation_request
    show_example_survey = !(params[:example_survey] and ['f','false','no','0'].include?(params[:example_survey].downcase))
    mail = PublicMailer.public_evaluation_request(user: User.first, question: Question.answered.last, cache_email: false, example_survey: show_example_survey)
    return render_mail(mail)
  end

  def public_comment_reply
    mail = PublicMailer.public_comment_reply(user: User.first, comment: Comment.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_question_activity
    mail = InternalMailer.aae_question_activity(user: User.first, question: Question.last, cache_email: false)
    return render_mail(mail)
  end

  
  
  protected
  
  def render_mail(mailpart)
    # send it through the inline style processing
    inlined_content = InlineStyle.process(mailpart.body.to_s,ignore_linked_stylesheets: true)
    render(:text => inlined_content, :layout => false)
  end

  def render_text_mail(mailpart, wordwrap=true)
    bodytext = wordwrap ? view_context.word_wrap(mailpart.body.to_s) : mailpart.body.to_s
    # wrap the text in some basic html
    email_text = <<-EMAILTEXT.strip_heredoc
      <!DOCTYPE html>
      <html>
        <head></head>
        <body>
          <pre>
            #{bodytext}
          </pre>
        </body>
      </html>
    EMAILTEXT
    render(:text => email_text, :layout => false)
  end


  # PLEASE NOTE: - these are built around the assumption of two part emails, one part html and one part text
  # these routines will need to be redesigned if images are ever attached, or there are additional parts
  def get_html_part(mail)
    if(!mail.multipart?)
      return mail
    else
      mail.parts.each do |part|
        if(part.mime_type == 'text/html')
          return part
        end
      end
    end
  end

  def get_text_part(mail)
    if(!mail.multipart?)
      return mail
    else
      mail.parts.each do |part|
        if(part.mime_type == 'text/plain')
          return part
        end
      end
    end
  end
  
end