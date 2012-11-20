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
  
  def internal_aae_public_comment
    mail = InternalMailer.aae_public_comment(user: User.first, comment: Comment.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_expert_comment
    mail = InternalMailer.aae_expert_comment(user: User.first, question: Question.last, expert_comment_event: QuestionEvent.last, cache_email: false)
    return render_mail(mail)
  end
  
  def internal_aae_reject
    mail = InternalMailer.aae_reject(user: User.first, rejected_event: QuestionEvent.where(event_state:QuestionEvent::REJECTED).first, cache_email: false)
    return render_mail(mail)
  end
  
  def public_expert_response
    mail = PublicMailer.public_expert_response(user: User.first, question: Question.answered.last, expert: User.offset(rand(User.count)).first, cache_email: false)
    return render_mail(mail)
  end
  
  def public_submission_acknowledgement
    mail = PublicMailer.public_submission_acknowledgement(user: User.first, question: Question.last, cache_email: false)
    return render_mail(mail)
  end
  
  def public_evaluation_request
    show_example_survey = !(params[:example_survey] and ['f','false','no','0'].include?(params[:example_survey].downcase))
    mail = PublicMailer.public_evaluation_request(user: User.first, question: Question.answered.last, cache_email: false, example_survey: show_example_survey)
    return render_mail(mail)
  end

  
  
  protected
  
  def render_mail(mail)
    # send it through the inline style processing
    inlined_content = InlineStyle.process(mail.body.to_s,ignore_linked_stylesheets: true)
    render(:text => inlined_content, :layout => false)
  end
  
end