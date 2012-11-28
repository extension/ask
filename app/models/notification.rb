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
  AAE_PUBLIC_COMMENT = 1005 # a public user posted another comment
  AAE_REJECT = 1006 # an expert has rejected a question
  #AAE_VACATION_RESPONSE = 1007 # received a vacation response to an assigned question
  AAE_INTERNAL_COMMENT = 1008 # an expert posted a comment
  #AAE_EXPERT_NOREPLY = 1009 # an expert replied to the no-reply address
  #AAE_WIDGET_BROADCAST = 1010 # broadcast email sent to all widget assignees 
    
  ##########################################
  #  Ask an Expert Notifications - Public
  
  NOTIFICATION_AAE_PUBLIC = [2000,2099]   # 'aae-public'
  AAE_PUBLIC_EXPERT_RESPONSE = 2001  # notification of an expert response, also "A Space Odyssey"
  #AAE_PUBLIC_NOREPLY = 2002 # public replied to the no-reply address
  #AAE_PUBLIC_NOREPLY_QUESTION = 2003 # public sent a new question to the no-reply address
  AAE_PUBLIC_EVALUATION_REQUEST = 2004 # request that the question submitter complete an evaluation
  AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT = 2010  # notification of submission, also "The Year We Make Contact"


  ##########################################
  
  
  
  def process
    #return true if (!Settings.send_notifications and !Settings.notification_whitelist.include?(self.notification_type))
    
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
    when AAE_PUBLIC_COMMENT
      process_aae_public_comment
    when AAE_REJECT
      process_aae_reject
    when AAE_INTERNAL_COMMENT
      process_aae_internal_comment
    when AAE_PUBLIC_EXPERT_RESPONSE
      process_aae_public_expert_response
    when AAE_PUBLIC_EVALUATION_REQUEST
      process_aae_public_evaluation_request
    when AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT
      process_aae_public_submission_acknowledgement
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
    InternalMailer.aae_assignment(user: self.notifiable.recipient, question: self.notifiable.question).deliver unless (self.notifiable.recipient.nil? || self.notifiable.recipient.email.nil?)
  end
  
  def process_aae_reassignment
    InternalMailer.aae_reassignment(user: self.notifiable.previous_handling_recipient, question: self.notifiable.question).deliver unless (self.notifiable.previous_handling_recipient.nil? || self.notifiable.recipient.email.nil?)
  end
  
  def process_aae_daily_summary
    User.not_retired.not_blocked.daily_summary_notification_list.each{|user| InternalMailer.aae_daily_summary(user: user, groups: user.daily_summary_group_list).deliver unless user.email.nil? or user.away? or user.daily_summary_group_list.empty?}
  end
  
  def process_aae_public_edit
    InternalMailer.aae_public_edit(user: self.notifiable.recipient, question: self.notifiable.question).deliver unless (self.notifiable.recipient.nil? || self.notifiable.recipient.email.nil?)
  end
  
  def process_aae_public_comment
    #NYI
  end
  
  def process_aae_internal_comment
    InternalMailer.aae_internal_comment(user: self.notifiable.recipient, question: self.notifiable.question, internal_comment_event: self.notifiable).deliver unless (self.notifiable.recipient.nil? || self.notifiable.recipient.email.nil?)
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
  
  def queue_delayed_notifications
    delayed_job = Delayed::Job.enqueue(NotificationJob.new(self.id), {:priority => 0, :run_at => self.delivery_time})
    self.update_attribute(:delayed_job_id, delayed_job.id)
  end
end
