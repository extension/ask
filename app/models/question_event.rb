# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class QuestionEvent < ActiveRecord::Base
  # includes
  include MarkupScrubber
  include CacheTools
  extend YearWeek
  # attributes
  serialize :updated_question_values

  # constants
  # #'s 3 and 4 were the old marked spam and marked non spam question events from darmok, these were
  # just pulled instead of renumbering all these so to not disturb the other status numbers being pulled over from the other sytem
  ASSIGNED_TO = 1
  RESOLVED = 2
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  TAG_CHANGE = 8
  WORKING_ON = 9
  EDIT_QUESTION = 10
  PUBLIC_RESPONSE = 11
  REOPEN = 12
  CLOSED = 13
  INTERNAL_COMMENT = 14
  ASSIGNED_TO_GROUP = 15
  CHANGED_GROUP = 16
  CHANGED_LOCATION = 17
  EXPERT_EDIT_QUESTION = 18
  EXPERT_EDIT_RESPONSE = 19
  CHANGED_TO_PUBLIC = 20
  CHANGED_TO_PRIVATE = 21
  CHANGED_FEATURED = 22
  ADDED_TAG = 23
  DELETED_TAG = 24
  PASSED_TO_WRANGLER = 25

  EVENT_TO_TEXT_MAPPING = { ASSIGNED_TO => 'assigned to',
                            RESOLVED => 'resolved by',
                            REACTIVATE => 're-activated by',
                            REJECTED => 'rejected by',
                            NO_ANSWER => 'no answer given',
                            TAG_CHANGE => 'tags edited by',
                            WORKING_ON => 'worked on by',
                            EDIT_QUESTION => 'edited question',
                            PUBLIC_RESPONSE => 'public response',
                            REOPEN => 'reopened',
                            CLOSED => 'closed',
                            INTERNAL_COMMENT => 'commented',
                            ASSIGNED_TO_GROUP => 'assigned to group',
                            CHANGED_GROUP => 'group changed',
                            CHANGED_LOCATION => 'location changed',
                            EXPERT_EDIT_QUESTION => 'expert edit of question',
                            EXPERT_EDIT_RESPONSE => 'expert edit of response',
                            CHANGED_TO_PUBLIC => 'changed to public by',
                            CHANGED_TO_PRIVATE => 'changed to private by',
                            CHANGED_FEATURED => 'changed featured by',
                            ADDED_TAG => 'tag added by',
                            DELETED_TAG => 'tag deleted by',
                            PASSED_TO_WRANGLER => 'handed off to'
                          }

  HANDLING_EVENTS = [ASSIGNED_TO, PASSED_TO_WRANGLER, ASSIGNED_TO_GROUP, RESOLVED, REJECTED, NO_ANSWER, CLOSED]
  SIGNIFICANT_EVENTS = [REJECTED,NO_ANSWER,EXPERT_EDIT_QUESTION,EXPERT_EDIT_RESPONSE,CHANGED_TO_PUBLIC,CHANGED_TO_PRIVATE]

  # reporting
  YEARWEEK_ACTIVE = "YEARWEEK(#{self.table_name}.created_at,3)"


  # associations
  belongs_to :question
  belongs_to :initiator, :class_name => "User", :foreign_key => "initiated_by_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :assigned_group, :class_name => "Group", :foreign_key => "recipient_group_id"
  belongs_to :previous_recipient, :class_name => "User", :foreign_key => "previous_recipient_id"
  belongs_to :previous_initiator,  :class_name => "User", :foreign_key => "previous_initiator_id"
  belongs_to :previous_handling_recipient, :class_name => "User", :foreign_key => "previous_handling_recipient_id"
  belongs_to :previous_handling_initiator,  :class_name => "User", :foreign_key => "previous_handling_initiator_id"
  belongs_to :contributing_question, :class_name => "Question", :foreign_key => "contributing_question_id"
  belongs_to :previous_group, class_name: 'Group'
  belongs_to :changed_group, class_name: 'Group'

  # scopes
  scope :latest, order("#{self.table_name}.created_at desc")
  scope :handling_events, where("event_state IN (#{HANDLING_EVENTS.join(',')})")
  scope :significant_events, where("event_state IN (#{SIGNIFICANT_EVENTS.join(',')})")
  scope :individual_assignments, where("event_state = ?",ASSIGNED_TO)
  scope :extension, where(is_extension: true)

  # validations

  # filters
  after_create :create_question_event_notification

  def self.log_resolution(question)
    question.contributing_question ? contributing_question = question.contributing_question : contributing_question = nil

    return self.log_event({:question => question,
                           :initiator => question.current_resolver,
                           :event_state => RESOLVED,
                           :response => question.current_response,
                           :contributing_question => contributing_question})
  end

  def self.log_assignment(question, recipient, initiated_by, assignment_comment)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_id => recipient.id,
      :event_state => ASSIGNED_TO,
      :response => assignment_comment})
  end

  def self.log_wrangler_handoff(question, recipient, initiated_by, handoff_reason)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_id => recipient.id,
      :event_state => PASSED_TO_WRANGLER,
      :response => handoff_reason})
  end

  def self.log_history_comment(question, initiated_by, history_comment)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => INTERNAL_COMMENT,
      :response => history_comment})
  end

  def self.log_group_assignment(question, group, initiated_by, assignment_comment)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_group_id => group.id,
      :recipient_id => nil,
      :event_state => ASSIGNED_TO_GROUP,
      :response => assignment_comment})
  end

  def self.log_group_change(options = {})
    question = options[:question]
    previous_group = options[:old_group]
    changed_group = options[:new_group]
    initiated_by = options[:initiated_by]
    if(question and previous_group and changed_group and initiated_by)
      return self.log_event(question: question, previous_group_id: previous_group.id, changed_group_id: changed_group.id, initiated_by_id: initiated_by.id, event_state: CHANGED_GROUP)
    else
      return false
    end
  end

  def self.log_featured_changed(question, initiated_by)
    return self.log_event({:question => question,
                           :initiated_by_id => initiated_by.id,
                           :updated_question_values => {:old_value => !question.featured, :new_value => question.featured},
                           :event_state => CHANGED_FEATURED
    })
  end

  def self.log_added_tag(question, initiated_by, tag)
    return self.log_event({:question => question,
                           :initiated_by_id => initiated_by.id,
                           :changed_tag => tag,
                           :event_state => ADDED_TAG
                           })
  end

  def self.log_deleted_tag(question, initiated_by, tag)
    return self.log_event({:question => question,
                           :initiated_by_id => initiated_by.id,
                           :changed_tag => tag,
                           :event_state => DELETED_TAG
                           })
  end

  def self.log_location_change(question, initiated_by, event_hash)
    return self.log_event({:question => question,
                           :initiated_by_id => initiated_by.id,
                           :updated_question_values => event_hash,
                           :event_state => CHANGED_LOCATION
                           })
  end

  def self.log_reopen(question, recipient, initiated_by, assignment_comment)
    question.update_attribute(:last_opened_at, Time.now)

    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_id => recipient.id,
      :event_state => REOPEN,
      :response => assignment_comment})
  end

  def self.log_public_edit(question)
    return self.log_event({:question => question,
      :event_state => EDIT_QUESTION,
      :additional_data => question.body})
  end

  def self.log_public_response(question, submitter_id)
    return self.log_event({:question => question,
      :initiated_by_id => User.system_user_id,
      :event_state => PUBLIC_RESPONSE,
      :submitter_id => submitter_id})
  end

  def self.log_working_on(question, initiated_by)
    return self.log_event({:question => question, :initiated_by_id => initiated_by.id, :event_state => WORKING_ON})
  end

  def self.log_make_public(question, initiated_by)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => CHANGED_TO_PUBLIC
    })
  end

  def self.log_make_private(question, initiated_by)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => CHANGED_TO_PRIVATE
    })
  end

  def self.log_question_edit_by_expert(question, initiated_by)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => EXPERT_EDIT_QUESTION
    })
  end

  def self.log_response_edit_by_expert(question, initiated_by, response)
    # kick off notification to expert (author of edited response) when their response is edited if a different expert edited it
    if response.is_expert? and !response.pending_expert_response_edit_notification?
      Notification.create(notifiable: response, created_by: initiated_by.id, recipient_id: response.resolver.id, notification_type: Notification::AAE_EXPERT_RESPONSE_EDIT, delivery_time: Settings.expert_response_edit_interval.from_now) unless initiated_by == response.resolver
    end

    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => EXPERT_EDIT_RESPONSE,
      :additional_data => response.id
    })
  end

  def self.log_reopen_to_group(question, group, initiated_by, assignment_comment)
    question.update_attribute(:last_opened_at, Time.now)

    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_group_id => group.id,
      :event_state => REOPEN,
      :response => assignment_comment})
  end

  def self.log_rejection(question)
    return self.log_event({:question => question,
      :initiated_by_id => question.current_resolver_id,
      :event_state => REJECTED,
      :response => question.current_response})
  end

  def self.log_reactivate(question, initiated_by)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => REACTIVATE})
  end

  def self.log_no_answer(question)
    return self.log_event({:question => question,
      :initiator => question.current_resolver,
      :event_state => NO_ANSWER,
      :response => question.current_response})
  end

  def self.log_close(question, initiated_by, close_out_reason)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => CLOSED,
      :response => close_out_reason})
  end

  def self.log_event(create_attributes = {})
    time_of_this_event = Time.now.utc
    question = create_attributes[:question]
    if create_attributes[:event_state] == ASSIGNED_TO || create_attributes[:event_state] == ASSIGNED_TO_GROUP
      question.update_column(:last_assigned_at, time_of_this_event)
    end

    # set is_extension
    if(create_attributes[:initiated_by_id] and user = User.find(create_attributes[:initiated_by_id]))
      create_attributes[:is_extension] = user.has_exid?
    elsif(create_attributes[:initiator])
      create_attributes[:is_extension] = create_attributes[:initiator].has_exid?
    end



    # gathering of previous events for metrics gathering for things like duration and handling rate,
    # if we want to keep track of this for a group context (user is being tracked here), we'll need to add more columns to the schema for groups

    # get last event
    last_event = question.question_events.latest.first
    if last_event.present?
      create_attributes[:duration_since_last] = (time_of_this_event - last_event.created_at).to_i
      create_attributes[:previous_recipient_id] = last_event.recipient_id
      create_attributes[:previous_initiator_id] = last_event.initiated_by_id
      create_attributes[:previous_event_id] = last_event.id
      # if not a handling event, get the last handling event
      if(!last_event.is_handling_event?)
        if(last_handling_event = question.question_events.handling_events.latest.first)
          create_attributes[:previous_handling_event_id] = last_handling_event.id
          create_attributes[:duration_since_last_handling_event] = (time_of_this_event - last_handling_event.created_at).to_i
          create_attributes[:previous_handling_event_state] = last_handling_event.event_state
          create_attributes[:previous_handling_recipient_id] = last_handling_event.recipient_id
          create_attributes[:previous_handling_initiator_id] = last_handling_event.initiated_by_id
        end
      else
        # last_event was a handling event - so use the last_event details to fill those values in
        create_attributes[:previous_handling_event_id] = last_event.id
        create_attributes[:duration_since_last_handling_event] = (time_of_this_event - last_event.created_at).to_i
        create_attributes[:previous_handling_event_state] = last_event.event_state
        create_attributes[:previous_handling_recipient_id] = last_event.recipient_id
        create_attributes[:previous_handling_initiator_id] = last_event.initiated_by_id
      end
    end

    return QuestionEvent.create(create_attributes)
  end

  def is_handling_event?
    HANDLING_EVENTS.include?(self.event_state)
  end

  def next_handling_event
    self.question.question_events.handling_events.where("question_events.created_at >= ?",self.created_at).where("question_events.id != ?",self.id).first
  end

  # NOTE THAT THE RECIPIENT_ID (AND PREVIOUS_RECIPIENT_ID AND PREVIOUS_HANDLING_RECIPIENT_ID) CAN BE NULL HERE DUE TO ASSIGNMENT TO GROUPS IN WHICH THE RECIPIENT_GROUP_ID IS SET
  def create_question_event_notification
    case self.event_state
    when REJECTED
      Notification.create(notifiable: self, created_by: self.initiated_by_id, recipient_id: self.previous_recipient_id, notification_type: Notification::AAE_REJECT, delivery_time: 1.minute.from_now ) unless (self.previous_recipient_id.nil? || (self.initiated_by_id == self.previous_recipient_id))
    when INTERNAL_COMMENT
      Notification.create(notifiable: self, created_by: 1, recipient_id: self.question.assignee.id, notification_type: Notification::AAE_INTERNAL_COMMENT, delivery_time: 1.minute.from_now ) unless (self.question.assignee.nil? or (self.question.assignee.id == self.initiated_by_id))
    when EDIT_QUESTION
      Notification.create(notifiable: self, created_by: 1, recipient_id: self.question.assignee.id, notification_type: Notification::AAE_PUBLIC_EDIT, delivery_time: 1.minute.from_now ) unless self.question.assignee.nil?
    when PUBLIC_RESPONSE
      Notification.create(notifiable: self.question.responses.last, created_by: 1, recipient_id: self.question.current_resolver.id, notification_type: Notification::AAE_PUBLIC_RESPONSE, delivery_time: 1.minute.from_now )
    when RESOLVED
      Notification.create(notifiable: self, created_by: self.initiated_by_id, recipient_id: self.question.submitter.id, notification_type: Notification::AAE_PUBLIC_EXPERT_RESPONSE, delivery_time: 1.minute.from_now )
      if !Notification.pending_activity_notification?(self.question)
        Notification.create(notifiable: self.question, notification_type: Notification::AAE_QUESTION_ACTIVITY, created_by: 1, recipient_id: 1, delivery_time: Settings.activity_notification_interval.from_now)
      end
    else
      true
    end
  end

  # attr_writer override for response to scrub html
  def response=(response)
    write_attribute(:response, self.cleanup_html(response))
  end

  # data
  def self.increase_group_concat_length
    set_group_concat_size_query = "SET SESSION group_concat_max_len = #{Settings.group_concat_max_len};"
    self.connection.execute(set_group_concat_size_query)
  end

  def self.earliest_activity_at
    with_scope do
      ea = self.minimum(:created_at)
      (ea < EpochDate::WWW_LAUNCH) ? EpochDate::WWW_LAUNCH : ea
    end
  end

  def self.latest_activity_at
    with_scope do
      self.maximum(:created_at)
    end
  end

  def self.stats_by_yearweek(cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{scope_sql: current_scope ? current_scope.to_sql : ''})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _stats_by_yearweek
        end
      end
    else
      with_scope do
        _stats_by_yearweek
      end
    end
  end

  def self._stats_by_yearweek
    metric = 'experts'
    stats = YearWeekStats.new
    # increase_group_concat_length
    with_scope do
      ea = self.extension.earliest_activity_at
      if(ea.blank?)
        return stats
      end
      la = self.extension.latest_activity_at

      metric_by_yearweek = self.extension.group(YEARWEEK_ACTIVE).count('DISTINCT(initiated_by_id)')

      year_weeks = self.year_weeks_between_dates(ea.to_date,la.to_date)
      year_weeks.each do |year,week|
        yw = self.yearweek(year,week)
        stats[yw] = {}
        metric_value = metric_by_yearweek[yw] || 0
        stats[yw][metric] = metric_value

        previous_year_key = self.yearweek(year-1,week)
        (previous_year,previous_week) = self.previous_year_week(year,week)
        previous_week_key = self.yearweek(previous_year,previous_week)

        previous_week = (metric_by_yearweek[previous_week_key]  ? metric_by_yearweek[previous_week_key] : 0)
        stats[yw]["previous_week_#{metric}"] = previous_week
        previous_year = (metric_by_yearweek[previous_year_key]  ? metric_by_yearweek[previous_year_key] : 0)
        stats[yw]["previous_year_#{metric}"] = previous_year

        # pct_change
        if(previous_week == 0)
          stats[yw]["pct_change_week_#{metric}"] = nil
        else
          stats[yw]["pct_change_week_#{metric}"] = (metric_value - previous_week) / previous_week.to_f
        end

        if(previous_year == 0)
          stats[yw]["pct_change_year_#{metric}"] = nil
        else
          stats[yw]["pct_change_year_#{metric}"] = (metric_value - previous_year) / previous_year.to_f
        end
      end
    end
    stats
  end


end
