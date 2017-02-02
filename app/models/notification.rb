# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Notification < ActiveRecord::Base
  ## attributes
  serialize :additional_data
  serialize :results

  ## validations

  ## filters
  before_create :set_delivery_time
  after_create  :queue_notification


  ## associations
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :notifiable, :polymorphic => true


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
  AAE_DATA_DOWNLOAD_AVAILABLE = 1018
  AAE_EXPERT_LOCATION_EDIT = 1019
  AAE_EXPERT_AWAY_REMINDER = 1020
  AAE_EXPERT_GROUP_EDIT = 1021


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
  AAE_EXPERT_RESPONSE_EDIT_TO_SUBMITTER = 2013
  AAE_PUBLIC_REJECTION_LOCATION = 2014
  AAE_PUBLIC_REJECTION_EXPERTS_UNAVAILABLE = 2015


  ##########################################

  def set_delivery_time
    if(self.delivery_time.blank?)
      self.delivery_time = Time.now
    end
  end

  def self.code_to_constant_string(code)
    constantslist = self.constants
    constantslist.each do |c|
      value = self.const_get(c)
      if(value.is_a?(Fixnum) and code == value)
        return c.to_s.downcase
      end
    end

    # if we got here?  return nil
    return nil
  end

  def queue_notification
    if(Settings.sidekiq_enabled and !self.process_on_create?)
      self.class.delay_until(self.delivery_time).delayed_notify(self.id)
    else
      self.notify
    end
  end

  def self.delayed_notify(record_id)
    if(record = find_by_id(record_id))
      record.notify
    end
  end


  def notify
    return true if (!Settings.send_notifications)

    method_name = self.class.code_to_constant_string(self.notification_type)
    methods = self.class.instance_methods.map{|m| m.to_s}
    if(methods.include?(method_name))
      begin
        self.send(method_name)
        self.update_attributes({processed: true})
      rescue NotificationError => e
        self.update_attributes({results: "ERROR! #{e.message}"})
      end
    else
      self.update_attributes({results: "ERROR! No method for this notification type"})
    end
  end

  def group_user_join
    self.notifiable.group.leaders.each{|leader| GroupMailer.group_user_join(user: leader, group: self.notifiable.group, new_member: self.notifiable.creator).deliver}
  end

  def group_user_left
    self.notifiable.group.leaders.each{|leader| GroupMailer.group_user_left(user: leader, group: self.notifiable.group, former_member: self.notifiable.creator).deliver}
  end

  def group_leader_join
    self.notifiable.group.leaders.each{|leader| GroupMailer.group_leader_join(user: leader, group: self.notifiable.group, new_leader: self.notifiable.creator).deliver}
  end

  def group_leader_left
    self.notifiable.group.leaders.each{|leader| GroupMailer.group_leader_left(user: leader, group: self.notifiable.group, former_leader: self.notifiable.creator).deliver}
  end

  def aae_assignment
    InternalMailer.aae_assignment(user: self.notifiable.assignee, question: self.notifiable).deliver unless (self.notifiable.assignee.nil? || self.notifiable.assignee.email.nil?)
  end

  def aae_reassignment
    user = User.find(self.recipient_id)
    InternalMailer.aae_reassignment(user: user, question: self.notifiable).deliver unless (user.nil? || user.email.nil?)
  end

  def aae_daily_summary
    User.not_retired.not_blocked.daily_summary_notification_list.each{|user| InternalMailer.aae_daily_summary(user: user, groups: user.daily_summary_group_list).deliver unless user.email.nil? or user.away? or user.daily_summary_group_list.empty?}
  end

  def aae_public_edit
    InternalMailer.aae_public_edit(user: self.notifiable.recipient, question: self.notifiable.question).deliver unless (self.notifiable.recipient.nil? || self.notifiable.recipient.email.nil?)
  end

  def aae_public_response
    InternalMailer.aae_public_response(user: self.notifiable.question.current_resolver, response: self.notifiable).deliver unless (self.notifiable.question.current_resolver.nil? || self.notifiable.question.current_resolver.email.nil?)
  end

  def aae_internal_comment
    InternalMailer.aae_internal_comment(user: self.notifiable.question.assignee, question: self.notifiable.question, internal_comment_event: self.notifiable).deliver unless (self.notifiable.question.assignee.nil? || self.notifiable.question.assignee.email.nil?)
  end

  def aae_assignment_group
    self.notifiable.assigned_group.incoming_notification_list.each{|user| InternalMailer.aae_assignment_group(user: user, question: self.notifiable).deliver unless user.email.nil? or self.notifiable.assignee == user }
  end

  def aae_reject
    InternalMailer.aae_reject(rejected_event: self.notifiable, user: self.notifiable.previous_handling_recipient).deliver unless (self.notifiable.previous_handling_recipient.nil? || (self.notifiable.initiator.id == self.notifiable.previous_handling_recipient.id))
  end

  def aae_public_expert_response
    PublicMailer.public_expert_response(user:self.notifiable.question.submitter, expert: self.notifiable.question.current_resolver, question: self.notifiable.question).deliver
  end

  def aae_public_evaluation_request
    PublicMailer.public_evaluation_request(user: self.notifiable.submitter, question: self.notifiable).deliver
    self.notifiable.update_attribute(:evaluation_sent,true)
  end

  def aae_public_submission_acknowledgement
    PublicMailer.public_submission_acknowledgement(user:self.notifiable.submitter, question: self.notifiable).deliver
  end

  def aae_public_rejection_location
    PublicMailer.public_rejection_location(user:self.notifiable.submitter, question: self.notifiable).deliver
  end

  def aae_public_rejection_experts_unavailable
    PublicMailer.public_rejection_experts_unavailable(user:self.notifiable.submitter, question: self.notifiable).deliver
  end

  def aae_expert_response_edit
    recipient = User.find_by_id(self.recipient_id)
    InternalMailer.aae_response_edit(user: recipient, question: self.notifiable.question, response: self.notifiable).deliver unless ((recipient.id == self.created_by) || recipient.blank? || recipient.retired? || recipient.email.blank?)
  end

  def aae_expert_response_edit_to_submitter
    recipient = User.find_by_id(self.recipient_id)
    PublicMailer.expert_response_edit(user: recipient, question: self.notifiable.question, response: self.notifiable).deliver unless (recipient.blank? || recipient.email.blank?)
  end

  def aae_question_activity
    self.notifiable.question_activity_preference_list.each{|pref| InternalMailer.aae_question_activity(user: pref.prefable, question: self.notifiable).deliver unless (pref.prefable.email.nil? || pref.prefable.id == self.created_by)}
  end

  def aae_expert_tag_edit
    InternalMailer.aae_expert_tag_edit(user: self.notifiable.user).deliver unless (self.notifiable.user.nil? || self.notifiable.user.email.nil?)
  end

  def aae_expert_vacation_edit
    InternalMailer.aae_expert_vacation_edit(user: self.notifiable.user).deliver unless (self.notifiable.user.nil? || self.notifiable.user.email.nil?)
  end

  def aae_expert_location_edit
    InternalMailer.aae_expert_location_edit(user: self.notifiable.user).deliver unless (self.notifiable.user.nil? || self.notifiable.user.email.nil?)
  end

  def aae_expert_group_edit
    InternalMailer.aae_expert_group_edit(user: self.notifiable.user).deliver unless (self.notifiable.user.nil? || self.notifiable.user.email.nil?)
  end

  def aae_expert_handling_reminder
    Question.submitted.where("last_assigned_at < ?", 3.days.ago).each{|question| InternalMailer.aae_expert_handling_reminder(user: question.assignee, question: question).deliver unless (question.assignee.nil? || question.assignee.away?)}
  end

  def aae_expert_away_reminder
    #2 week reminder
    two_week_vacators = User.valid_users.exid_holder.where("DATE(vacated_aae_at) <= '#{2.weeks.ago.to_date.to_s(:db)}' AND
                first_aae_away_reminder = false AND
                second_aae_away_reminder = false")

    #one month reminder
    one_month_vacators = User.valid_users.exid_holder.where("DATE(vacated_aae_at) <= '#{4.weeks.ago.to_date.to_s(:db)}' AND
                second_aae_away_reminder = false")

    # loop through all the experts who have opted out of receiving questions according to said criteria above
    two_week_vacators.each do |vacator|
      InternalMailer.aae_expert_away_reminder(user: vacator, away_date: vacator.vacated_aae_at).deliver
      vacator.update_attribute(:first_aae_away_reminder, true)
    end

    one_month_vacators.each do |vacator|
      InternalMailer.aae_expert_away_reminder(user: vacator, away_date: vacator.vacated_aae_at).deliver
      vacator.update_attribute(:second_aae_away_reminder, true)
    end
  end


  def aae_data_download_available
     if(self.notifiable.notifylist)
      self.notifiable.notifylist.each do |id|
        if(person = User.find_by_id(id))
          InternalMailer.data_download_available({download: self.notifiable, notification: self, recipient: person}).deliver
        end
      end
    end
    # clear notify list
    self.notifiable.notifylist = []
    self.notifiable.save
  end

  def self.pending_activity_notification?(notifiable)
    Notification.where(notifiable_id: notifiable.id, notification_type: AAE_QUESTION_ACTIVITY,
                       delivery_time: Time.now..Settings.activity_notification_interval.from_now).size > 0
  end

  def self.pending_tag_edit_notification?(user_event)
     Notification.where(notification_type: AAE_EXPERT_TAG_EDIT, recipient_id: user_event.user.id,
                        delivery_time: Settings.user_event_notification_interval.ago..Time.zone.now + 1.minute).size > 0
  end

  def self.pending_location_edit_notification?(user_event)
     Notification.where(notification_type: AAE_EXPERT_LOCATION_EDIT, recipient_id: user_event.user.id,
                        delivery_time: Settings.user_event_notification_interval.ago..Time.zone.now + 1.minute).size > 0
  end

end
