# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Notification < ActiveRecord::Base
  belongs_to :notifiable, :polymorphic => true
  serialize :additional_data
  after_create :queue_delayed_notifications
  
  
  ###############################
  #  Group Notifications
  
  NOTIFICATION_GROUP = [100,999]   # 'group notifications in this range'
  
  GROUP_USER_JOIN = 101
  GROUP_USER_LEFT = 102
  
  GROUP_LEADER_JOIN = 201
  GROUP_LEADER_LEFT = 202

  ##########################################
  #  Ask an Expert Notifications - Internal

  NOTIFICATION_AAE_INTERNAL = [1000,1999]   # 'aae-internal'
  AAE_ASSIGNMENT = 1001  # assignment notification
  AAE_REASSIGNMENT = 1002  # reassignment notification
  AAE_DAILY_SUMMARY = 1003  # escalation notification
  AAE_PUBLIC_EDIT = 1004  # a public user edited their question
  AAE_PUBLIC_RESPONSE = 1005 # a public user posted a response
  AAE_REJECT = 1006 # an expert has rejected a question
  #AAE_VACATION_RESPONSE = 1007 # received a vacation response to an assigned question
  AAE_INTERNAL_COMMENT = 1008 # an expert posted a comment
  #AAE_EXPERT_NOREPLY = 1009 # an expert replied to the no-reply address
  #AAE_WIDGET_BROADCAST = 1010 # broadcast email sent to all widget assignees
  AAE_ASSIGNMENT_GROUP = 1011 
  AAE_QUESTION_ACTIVITY = 1012
  AAE_EXPERT_TAG_EDIT = 1013
  AAE_EXPERT_VACATION_EDIT = 1014
  AAE_EXPERT_HANDLING_REMINDER = 1015
  AAE_EXPERT_PUBLIC_COMMENT = 1016
  AAE_EXPERT_RESPONSE_EDIT = 1017
    
  ##########################################
  #  Ask an Expert Notifications - Public
  
  NOTIFICATION_AAE_PUBLIC = [2000,2099]   # 'aae-public'
  AAE_PUBLIC_EXPERT_RESPONSE = 2001  # notification of an expert response, also "A Space Odyssey"
  #AAE_PUBLIC_NOREPLY = 2002 # public replied to the no-reply address
  #AAE_PUBLIC_NOREPLY_QUESTION = 2003 # public sent a new question to the no-reply address
  AAE_PUBLIC_EVALUATION_REQUEST = 2004 # request that the question submitter complete an evaluation
  AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT = 2010  # notification of submission, also "The Year We Make Contact"
  AAE_PUBLIC_COMMENT_REPLY = 2011
  AAE_PUBLIC_COMMENT = 2012

  ##########################################
  
  
  
  def process
    return true if (!Settings.send_notifications)
    
    case self.notification_type
    when GROUP_USER_JOIN
      process_group_user_join
    when GROUP_USER_LEFT
      process_group_user_left
    when GROUP_LEADER_JOIN
      process_group_leader_join
    when GROUP_LEADER_LEFT
      process_group_leader_left
    when AAE_ASSIGNMENT
      process_aae_assignment
    when AAE_REASSIGNMENT
      process_aae_reassignment
    when AAE_DAILY_SUMMARY
      process_aae_daily_summary
    when AAE_PUBLIC_EDIT
      process_aae_public_edit
    when AAE_PUBLIC_RESPONSE
      process_aae_public_response
    when AAE_REJECT
      process_aae_reject
    when AAE_INTERNAL_COMMENT
      process_aae_internal_comment
    when AAE_ASSIGNMENT_GROUP
      process_aae_assignment_group
    when AAE_PUBLIC_EXPERT_RESPONSE
      process_aae_public_expert_response
    when AAE_PUBLIC_EVALUATION_REQUEST
      process_aae_public_evaluation_request
    when AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT
      process_aae_public_submission_acknowledgement
    when AAE_PUBLIC_COMMENT_REPLY
      process_aae_public_comment_reply
    when AAE_PUBLIC_COMMENT
      process_aae_public_comment
    when AAE_QUESTION_ACTIVITY
      process_aae_question_activity
    when AAE_EXPERT_TAG_EDIT
      process_aae_expert_tag_edit
    when AAE_EXPERT_VACATION_EDIT
      process_aae_expert_vacation_edit
    when AAE_EXPERT_HANDLING_REMINDER
      process_aae_expert_handling_reminder
    when AAE_EXPERT_PUBLIC_COMMENT
      process_aae_expert_public_comment
    when AAE_EXPERT_RESPONSE_EDIT
      process aae_expert_response_edit
    else
      # nothing
    end
  end
  
  def process_group_user_join
    self.notifiable.group.leaders.each{|leader| GroupMailer.group_user_join(user: leader, group: self.notifiable.group, new_member: self.notifiable.creator).deliver}
  end
  
  def process_group_user_left
    self.notifiable.group.leaders.each{|leader| GroupMailer.group_user_left(user: leader, group: self.notifiable.group, former_member: self.notifiable.creator).deliver}
  end
  
  def process_group_leader_join
    self.notifiable.group.leaders.each{|leader| GroupMailer.group_leader_join(user: leader, group: self.notifiable.group, new_leader: self.notifiable.creator).deliver}
  end
  
  def process_group_leader_left
    self.notifiable.group.leaders.each{|leader| GroupMailer.group_leader_left(user: leader, group: self.notifiable.group, former_leader: self.notifiable.creator).deliver}
  end  
  
  def process_aae_assignment
    InternalMailer.aae_assignment(user: self.notifiable.assignee, question: self.notifiable).deliver unless (self.notifiable.assignee.nil? || self.notifiable.assignee.email.nil?)
  end
  
  def process_aae_reassignment
    user = User.find(self.recipient_id)
    InternalMailer.aae_reassignment(user: user, question: self.notifiable).deliver unless (user.nil? || user.email.nil?)
  end
  
  def process_aae_daily_summary
    User.not_retired.not_blocked.daily_summary_notification_list.each{|user| InternalMailer.aae_daily_summary(user: user, groups: user.daily_summary_group_list).deliver unless user.email.nil? or user.away? or user.daily_summary_group_list.empty?}
  end
  
  def process_aae_public_edit
    InternalMailer.aae_public_edit(user: self.notifiable.recipient, question: self.notifiable.question).deliver unless (self.notifiable.recipient.nil? || self.notifiable.recipient.email.nil?)
  end
  
  def process_aae_public_response
    InternalMailer.aae_public_response(user: self.notifiable.question.current_resolver, response: self.notifiable).deliver unless (self.notifiable.question.current_resolver.nil? || self.notifiable.question.current_resolver.email.nil?)
  end
  
  def process_aae_internal_comment
    InternalMailer.aae_internal_comment(user: self.notifiable.question.assignee, question: self.notifiable.question, internal_comment_event: self.notifiable).deliver unless (self.notifiable.question.assignee.nil? || self.notifiable.question.assignee.email.nil?)
  end
  
  def process_aae_assignment_group
    self.notifiable.assigned_group.incoming_notification_list.each{|user| InternalMailer.aae_assignment_group(user: user, question: self.notifiable).deliver unless user.email.nil? or self.notifiable.assignee == user }
  end
  
  def process_aae_reject
    InternalMailer.aae_reject(rejected_event: self.notifiable, user: self.notifiable.previous_handling_recipient).deliver unless self.notifiable.previous_handling_recipient.nil?
  end
  
  def process_aae_public_expert_response
    PublicMailer.public_expert_response(user:self.notifiable.question.submitter, expert: self.notifiable.question.current_resolver, question: self.notifiable.question).deliver
  end
  
  def process_aae_public_evaluation_request
    PublicMailer.public_evaluation_request(user: self.notifiable.submitter, question: self.notifiable).deliver
    self.notifiable.update_attribute(:evaluation_sent,true)
  end

  def process_aae_public_submission_acknowledgement
    PublicMailer.public_submission_acknowledgement(user:self.notifiable.submitter, question: self.notifiable).deliver
  end
  
  # send comment notification to public parent comment poster (if exists) 
  def process_aae_public_comment_reply
    PublicMailer.public_comment_reply(user: self.notifiable.parent.user, comment: self.notifiable).deliver unless (self.notifiable.parent.user.nil? || self.notifiable.parent.user.email.nil? || self.notifiable.parent.user == self.notifiable.user)
  end
  
  # send comment notification to submitter of question
  def process_aae_public_comment
    question_submitter = self.notifiable.question.submitter
    # make sure the question submitter has not opted out of receiving comment notifications
    if self.notifiable.question.opted_into_comment_notifications?(question_submitter)
      question_watchers = self.notifiable.question.question_activity_preference_list.map{|pref| pref.prefable}
      # don't want double emails going out to question watchers and parent comment submitters or an email going to the submitter of the comment
      if !(self.notifiable.is_reply? && question_submitter == self.notifiable.parent.user) && !question_watchers.include?(question_submitter) && !(question_submitter.id == self.created_by)
        PublicMailer.public_comment_submit(user: question_submitter, comment: self.notifiable).deliver unless question_submitter.nil? || question_submitter.email.nil?
      end
    end
  end
  
  def process_aae_expert_response_edit
    recipient = User.find_by_id(self.recipient_id)
    InternalMailer.aae_response_edit(user: recipient, question: self.notifiable.question, response: self.notifiable).deliver unless ((recipient.id == self.created_by) || recipient.blank? || recipient.retired? || recipient.email.blank?)
  end
  
  # send comment notifications to:
  # those watching the question (signed up to be notified of activity)
  # all resolvers of the question
  def process_aae_expert_public_comment
    question_watchers = self.notifiable.question.question_activity_preference_list.map{|pref| pref.prefable}
    # send emails to the watchers that were not the submitter of the parent comment (already handled in reply notification) and 
    # who did not post the comment themselves or who did not submit the question (already handled in submission notification)
    question_watchers.each{|watcher| InternalMailer.aae_question_activity(user: watcher, question: self.notifiable.question).deliver unless (watcher.id == self.created_by || watcher == self.notifiable.question.submitter || (self.notifiable.is_reply? && watcher == self.notifiable.parent.user))}
    # make sure we don't have a double email to the intersection of question watchers and question resolvers
    resolver_list = self.notifiable.question.resolver_list - question_watchers
    # don't deliver email unless the expert did not post the comment, or the expert authored the parent comment (already handled in reply notification)
    resolver_list.each{|expert| InternalMailer.aae_comment(user: expert, question: self.notifiable.question, comment: self.notifiable).deliver unless (expert.id == self.created_by || (self.notifiable.is_reply? && expert == self.notifiable.parent.user))}
  end
  
  def process_aae_question_activity
    self.notifiable.question_activity_preference_list.each{|pref| InternalMailer.aae_question_activity(user: pref.prefable, question: self.notifiable).deliver unless (pref.prefable.email.nil? || pref.prefable.id == self.created_by)}
  end
  
  def process_aae_expert_tag_edit
    InternalMailer.aae_expert_tag_edit(user: self.notifiable.user).deliver unless (self.notifiable.user.nil? || self.notifiable.user.email.nil?)
  end

  def process_aae_expert_vacation_edit
    InternalMailer.aae_expert_vacation_edit(user: self.notifiable.user).deliver unless (self.notifiable.user.nil? || self.notifiable.user.email.nil?)
  end
  
  def process_aae_expert_handling_reminder
    Question.submitted.where("last_assigned_at < ?", 3.days.ago).each{|question| InternalMailer.aae_expert_handling_reminder(user: question.assignee, question: question).deliver unless (question.assignee.nil? || question.assignee.away?)}
  end
  
  def queue_delayed_notifications
    delayed_job = Delayed::Job.enqueue(NotificationJob.new(self.id), {:priority => 0, :run_at => self.delivery_time})
    self.update_attribute(:delayed_job_id, delayed_job.id)
  end
  
  def self.pending_activity_notification?(notifiable)
    Notification.where(notifiable_id: notifiable.id, notification_type: AAE_QUESTION_ACTIVITY, delivery_time: Time.now..Settings.activity_notification_interval.from_now).size > 0
  end
end
