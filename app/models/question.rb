# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Question < ActiveRecord::Base
  include MarkupScrubber
  include Rakismet::Model
  include CacheTools
  rakismet_attrs :author_email => :email, :content => :body


  class Question::Image < Asset
    has_attached_file :attachment, 
                      :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension",
                      :styles => Proc.new { |attachment| attachment.instance.styles }
                        attr_accessible :attachment
    # http://www.ryanalynporter.com/2012/06/07/resizing-thumbnails-on-demand-with-paperclip-and-rails/
    def dynamic_style_format_symbol
        URI.escape(@dynamic_style_format).to_sym
      end

      def styles
        unless @dynamic_style_format.blank?
          { dynamic_style_format_symbol => @dynamic_style_format }
        else
          { :medium => "300x300>", :thumb => "100x100>" }
        end
      end

      def dynamic_attachment_url(format)
        @dynamic_style_format = format
        attachment.reprocess!(dynamic_style_format_symbol) unless attachment.exists?(dynamic_style_format_symbol)
        attachment.url(dynamic_style_format_symbol)
      end
  end

  has_many :images, :as => :assetable, :class_name => "Question::Image", :dependent => :destroy
  belongs_to :assignee, :class_name => "User", :foreign_key => "assignee_id"
  belongs_to :current_resolver, :class_name => "User", :foreign_key => "current_resolver_id"
  belongs_to :location
  belongs_to :county
  belongs_to :original_location, :class_name => "Location", :foreign_key => "original_location_id"
  belongs_to :original_county, :class_name => "County", :foreign_key => "original_county_id"
  belongs_to :widget 
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  belongs_to :assigned_group, :class_name => "Group", :foreign_key => "assigned_group_id"
  belongs_to :contributing_question, :class_name => "Question", :foreign_key => "contributing_question_id"
  belongs_to :original_group, :class_name => "Group", :foreign_key => "original_group_id"
  
  has_many :comments
  has_many :ratings
  has_many :responses
  has_many :question_events
  has_many :question_viewlogs, dependent: :destroy
  
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  
  accepts_nested_attributes_for :images, :allow_destroy => true
  accepts_nested_attributes_for :responses
  
  validates :body, :presence => true
  validate :validate_attachments
  
  before_create :generate_fingerprint, :set_last_opened


  after_create :check_spam, :auto_assign_by_preference, :notify_submitter, :send_global_widget_notifications, :index_me
  after_update :index_me


  # sunspot/solr search
  searchable :auto_index => false do
    text :title, more_like_this: true
    text :body, more_like_this: true
    text :response_list, more_like_this: true
    integer :status_state
    boolean :is_private
  end  
  
  # status numbers (for status_state)     
  STATUS_SUBMITTED = 1
  STATUS_RESOLVED = 2
  STATUS_NO_ANSWER = 3
  STATUS_REJECTED = 4
  STATUS_CLOSED = 5
  
  # status text (to be used when a text version of the status is needed)
  SUBMITTED_TEXT = 'submitted'
  RESOLVED_TEXT = 'resolved'
  ANSWERED_TEXT = 'answered'
  NO_ANSWER_TEXT = 'not_answered'
  REJECTED_TEXT = 'rejected'
  CLOSED_TEXT = 'closed'
  
  # privacy reasons
  PRIVACY_CODE_TO_TEXT = {
   1 => "public",
   2 => "private by submitter",
   3 => "private by expert",
   4 => "private because of rejected/duplicate"
  }
  
  # privacy constants
  PRIVACY_REASON_PUBLIC = 1
  PRIVACY_REASON_SUBMITTER = 2
  PRIVACY_REASON_EXPERT = 3
  PRIVACY_REASON_REJECTED = 4
  
  # disclaimer info
  EXPERT_DISCLAIMER = "This message for informational purposes only. " +  
                      "It is not intended to be a substitute for personalized professional advice. For specific local information, " + 
                      "contact your local county Cooperative Extension office or other qualified professionals." + 
                      "eXtension Foundation does not recommend or endorse any specific tests, professional, products, procedures, opinions, or other information " + 
                      "that may be mentioned. Reliance on any information provided by eXtension Foundation, employees, suppliers, member universities, or other " + 
                      "third parties through eXtension is solely at the user's own risk. All eXtension content and communication is subject to  the terms of " + 
                      "use http://www.extension.org/main/termsofuse which may be revised at any time."
  
  
  DEFAULT_SUBMITTER_NAME = "Anonymous Guest"
  WRANGLER_REASSIGN_COMMENT = "This question has been assigned to you because the previous assignee clicked the 'Hand off to a Question Wrangler' button."
  
  PUBLIC_RESPONSE_REASSIGNMENT_COMMENT = "This question has been reassigned to you because a new comment has been posted to your response. Please " +
  "reply using the link below or close the question out if no reply is needed. Thank You."
  
  DECLINE_ANSWER = "Thank you for your question for eXtension. The topic area in which you've made a request is not yet fully staffed by eXtension experts and therefore we cannot provide you with a timely answer. Instead, if you live in the United States, please consider contacting the Cooperative Extension office closest to you. Simply go to http://www.extension.org, drop in your zip code and choose the office that is most convenient for you.  We apologize that we can't help you right now,  but please come back to eXtension to check in as we grow and add experts."
  
  scope :public_visible, conditions: { is_private: false }
  scope :public_visible_answered, conditions: { is_private: false, :status_state => STATUS_RESOLVED }
  scope :public_visible_unanswered, conditions: { is_private: false, :status_state => STATUS_SUBMITTED }
  scope :public_visible_with_images_answered, :include => :images, :conditions => "assets.id IS NOT NULL AND is_private = false AND status_state = #{STATUS_RESOLVED}"
  scope :public_visible_with_images_unanswered, :include => :images, :conditions => "assets.id IS NOT NULL AND is_private = false AND status_state = #{STATUS_SUBMITTED}"
  scope :from_group, lambda {|group_id| {:conditions => {:assigned_group_id => group_id}}}
  scope :tagged_with, lambda {|tag_id| 
    {:include => {:taggings => :tag}, :conditions => "tags.id = '#{tag_id}' AND taggings.taggable_type = 'Question'"}
  }
  scope :by_location, lambda {|location| {:conditions => {:location_id => location.id}}}
  scope :by_county, lambda {|county| {:conditions => {:county_id => county.id}}}
  scope :answered, where(:status_state => STATUS_RESOLVED)
  scope :submitted, where(:status_state => STATUS_SUBMITTED)
  scope :not_rejected, conditions: "status_state <> #{STATUS_REJECTED}"
  # special scope for returning an empty AR association
  scope :none, where('1 = 0')

  # check for spam - given the process flow, not sure
  # this is a candidate for delayed job
  def check_spam
    if self.spam?
      self.add_resolution(STATUS_REJECTED, User.system_user, 'Spam')
    end
    true
  end

  # for purposes of solr search
  def response_list
    self.responses.map(&:body).join(' ')
  end

  # return a list of similar articles using sunspot
  def similar_questions(count = 4)
    search_results = self.more_like_this do
      without(:status_state, STATUS_REJECTED)
      paginate(:page => 1, :per_page => count)
      adjust_solr_params do |params|
        params[:fl] = 'id,score'
      end
    end
    return_results = {}
    search_results.each_hit_with_result do |hit,event|
      return_results[event] = hit.score
    end
    return_results
  end
  
  def public_similar_questions(count = 4)
    search_results = self.more_like_this do
      with(:is_private, false)
      without(:status_state, STATUS_REJECTED)
      paginate(:page => 1, :per_page => count)
      adjust_solr_params do |params|
        params[:fl] = 'id,score'
      end
    end
    return_results = {}
    search_results.each_hit_with_result do |hit,event|
      return_results[event] = hit.score
    end
    return_results
  end
  
  def email
    self.submitter.present? ? self.submitter.email : ''
  end
  
  def auto_assign_by_preference
    return true if self.spam?
    if existing_question = Question.joins(:submitter).find(:first, :conditions => ["questions.id != #{self.id} and questions.body = ? and users.email = '#{self.email}'", self.body])
      reject_msg = "This question is a duplicate of question ##{existing_question.id}"
      self.add_resolution(STATUS_REJECTED, User.system_user, reject_msg)
      return
    end

    if Settings.auto_assign_incoming_questions
      auto_assign
    end
  end
  
  def title
    if self[:title].present?
      return self[:title]
    else 
      return self.html_to_text(self[:body].squish).truncate(80, separator: ' ')
    end
  end

  # attr_writer override for body to scrub html
  def body=(bodycontent)
    write_attribute(:body, self.cleanup_html(bodycontent))
  end

  # attr_writer override for title to strip html
  def title=(titlecontent)
    write_attribute(:title, self.html_to_text(titlecontent))
  end

    
  def auto_assign
    assignee = nil
    system_user = User.system_user
    
    group = self.assigned_group
    if (group.assignment_outside_locations || group.expertise_locations.include?(self.location))
      # if group individual assignment is not turned on for a group, then we log that it was assigned to the group.
      # the group designation has already been taken care of with the saving of the question, and when we don't have an individual assignment, but a group designation,
      # it is considered assigned to the group and not an individual.
      if group.individual_assignment == false
        QuestionEvent.log_group_assignment(self, group, system_user, nil)    
        return
      end
      
      if group.assignees.length > 0
        if self.county.present?
          assignee = pick_user_from_list(group.assignees.with_expertise_county(self.county.id))
        end
        if !assignee && self.location.present?
          assignee = pick_user_from_list(group.assignees.with_expertise_location_all_counties(self.location.id))
        end
        if !assignee 
          assignee = pick_user_from_list(group.assignees.active.route_from_anywhere)
        end
        # still aint got no one? assign to a group leader
        if !assignee
          if group.leaders.active.length > 0
            assignee = pick_user_from_list(group.leaders.active)
          # still aint got no one? really?? Wrangle that bad boy.
          else
            assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county))
          end
        end
      # if individual assignment is turned on for the group and there are no active assignees, wrangle it
      else
        assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county))
      end
    else
      # send to the question wrangler group if the location of the question is not in the location of the group and 
      # the group is not receiving questions from outside their defined locations.
      assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county))
    end
    
    if assignee
      assign_to(assignee, system_user, nil)
    else
      return
    end
  end
  
  def add_history_comment(user, comment)
    QuestionEvent.log_history_comment(self, user, comment)
  end
  
  # Assigns the question to the user, logs the assignment, and sends an email
  # to the assignee letting them know that the question has been assigned to
  # them.
  def assign_to(user, assigned_by, comment, public_reopen = false, public_comment = nil)
    raise ArgumentError unless user and user.instance_of?(User)  

    # don't bother doing anything if this is assignment to the person already assigned unless it's 
    # a question that's been responded to by the public after it's been resolved that then gets 
    # assigned to whomever the question was last assigned to.
    return true if self.assignee && user.id == assignee.id && public_reopen == false
    
    if(self.assignee.present? && (assigned_by != self.assignee))
      is_reassign = true
      previously_assigned_to = self.assignee
    else
      is_reassign = false
    end

    # update and log
    self.update_attribute(:assignee, user)  
    
    QuestionEvent.log_assignment(self,user,assigned_by,comment)    
    # if this is a reopen reassignment due to the public user commenting on the sq                                  
    if public_comment
      asker_comment = public_comment.body
    else
      asker_comment = nil
    end
    
    Notification.create(notifiable: self, created_by: 1, recipient_id: self.assignee_id, notification_type: Notification::AAE_ASSIGNMENT, delivery_time: 1.minute.from_now ) unless self.assignee.nil? #individual assignment notification
    if(is_reassign and public_reopen == false)
      Notification.create(notifiable: self, created_by: 1, recipient_id: previously_assigned_to.id, notification_type: Notification::AAE_REASSIGNMENT, delivery_time: 1.minute.from_now )
    end
      
  end
  
  # Assigns the question to the group, logs the assignment, and sends an email
  # to the group members signed up for notifications notifying them that a question has been assigned to their group
  def assign_to_group(group, assigned_by, comment)
    raise ArgumentError unless group and group.instance_of?(Group)  

    # don't bother doing anything if this is an assignment to the group already assigned. 
    # if it has an assignee, we need to take the assignee off and log this change.
    return true if self.assigned_group && (group.id == self.assigned_group.id) && self.assignee.nil?
    
    #keep track of the previously assigned user for reassignment if there was one
    if self.assignee.present?
      previously_assigned_user = self.assignee
      is_reassign = true
    end
    
    # update and log
    current_assigned_group = self.assigned_group
    self.update_attributes(:assigned_group => group, :assignee => nil)
    QuestionEvent.log_group_assignment(self,group,assigned_by,comment)
    if(current_assigned_group != group)
      QuestionEvent.log_group_change(question: self, old_group: current_assigned_group, new_group: group, initiated_by: assigned_by)
    end
    
    # after reassigning to another group manually, updating the group, logging the group assignment, and logging the group change, 
    # if the individual assignment flag is set to true for this group, assign to an individual within this group using the routing algorithm.
    if group.individual_assignment == true
      auto_assign
    else
      if(is_reassign)
        Notification.create(notifiable: self, created_by: assigned_by.id, recipient_id: previously_assigned_user.id, notification_type: Notification::AAE_REASSIGNMENT, delivery_time: 1.minute.from_now )
      end
    end
    Notification.create(notifiable: self, created_by: assigned_by.id, recipient_id: 1, notification_type: Notification::AAE_ASSIGNMENT_GROUP, delivery_time: 1.minute.from_now )  unless self.assigned_group.incoming_notification_list.empty?  
  end

  def change_group(group, changed_by)
    current_assigned_group = self.assigned_group
    if(current_assigned_group != group)
      if(self.update_attribute(:assigned_group,group))
        QuestionEvent.log_group_change(question: self, old_group: current_assigned_group, new_group: group, initiated_by: changed_by)
        return true
      else
        return false
      end
    else
      return true
    end
  end

  # updates the question, creates a response and  
  # calls the function to log a new resolved question event 
  def add_resolution(q_status, resolver, response, signature = nil, contributing_question = nil, response_params = nil)

    t = Time.now

    case q_status
      when STATUS_RESOLVED    
        response_attributes = {:resolver => resolver, 
                               :question => self, 
                               :body => response,
                               :sent => true, 
                               :contributing_question => contributing_question, 
                               :signature => signature}
        response_attributes.merge!(response_params) if response_params.present?
        @response = Response.new(response_attributes) 
        if @response.valid?
          self.update_attributes(:status => Question.convert_to_string(q_status), :status_state =>  q_status, :current_resolver => resolver, :current_response => response, :contributing_question => contributing_question, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
          @response.save
          QuestionEvent.log_resolution(self)    
        else
          raise "There is an error in your response: #{@response.errors.full_messages.to_sentence}"
        end
      when STATUS_NO_ANSWER
        response_attributes = {:resolver => resolver, 
                               :question => self, 
                               :body => response,
                               :sent => true, 
                               :contributing_question => contributing_question, 
                               :signature => signature}
        response_attributes.merge!(response_params) if response_params.present?
        @response = Response.new(response_attributes)
        if @response.valid?
          self.update_attributes(:status => Question.convert_to_string(q_status), :status_state =>  q_status, :current_resolver => resolver, :current_response => response, :contributing_question => contributing_question, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
          @response.save
          QuestionEvent.log_no_answer(self)  
        else
          raise "There is an error in your response: #{@response.errors.full_messages.to_sentence}"
        end
      when STATUS_REJECTED
        self.update_attributes(:status => Question.convert_to_string(q_status), :status_state => q_status, :current_response => response, :current_resolver => resolver, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"), :is_private => true, :is_private_reason => PRIVACY_REASON_REJECTED)
        QuestionEvent.log_rejection(self)
    end
  end
  
  # for the 'Hand off to a Question Wrangler' functionality
  def assign_to_question_wrangler(assigned_by)
    assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county))
    comment = WRANGLER_REASSIGN_COMMENT
    assign_to(assignee, assigned_by, comment)
    self.save
    return assignee
  end
  
  def resolved?
    self.status_state != STATUS_SUBMITTED
  end
  
  def assigned_to_group_queue?
    self.assignee_id.nil? and self.assigned_group_id.present? ? true : false
  end
  
  # utility function to convert status_state numbers to status strings
  def self.convert_to_string(status_number)
    case status_number
    when STATUS_SUBMITTED
      'submitted'
    when STATUS_RESOLVED
      'resolved'
    when STATUS_NO_ANSWER
      'no answer'
    when STATUS_REJECTED
      'rejected'
    when STATUS_CLOSED
      'closed'
    else
      nil
    end
  end
  
  def submitter_name
    if self.submitter_firstname.present? && self.submitter_lastname.present?
      submitter_name = self.submitter_firstname + " " + self.submitter_lastname
    else
      submitter_name = self.submitter.name if self.submitter
    end
    
    if submitter_name.blank?
      submitter_name = DEFAULT_SUBMITTER_NAME 
    end

    return submitter_name
  end
  
  def set_tag(tag)
    if self.tags.collect{|t| Tag.normalizename(t.name)}.include?(Tag.normalizename(tag))
      return false
    else 
      if(tag = Tag.find_or_create_by_name(Tag.normalizename(tag)))
        begin
          self.tags << tag
        rescue
          return false
        end  
        return tag
      end
    end
  end
  
  # get the event of the last response given for a question
  def last_response
    question_event = self.question_events.find(:first, :conditions => "event_state = #{QuestionEvent::RESOLVED} OR event_state = #{QuestionEvent::NO_ANSWER}", :order => "created_at DESC")
    return question_event if question_event
    return nil
  end
  
  def validate_attachments
    allowable_types = ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png']
    images.each {|i| self.errors[:base] << "Image is over 5MB" if i.attachment_file_size > 5.megabytes}
    images.each {|i| self.errors[:base] << "Image is not correct file type (.jpg, .png, or .gif allowed)" if !allowable_types.include?(i.attachment_content_type)}
  end
   
  def index_me
    return true if self.spam?
    # if the responses changed on the last update, we don't need to reindex, because that's handled in the response hook, but if the responses
    # did not change and these other fields did, we need to go ahead and reindex here. example: a question gets it's status changed to something else, say rejected, then 
    # since a response is not created, then this hook will need to execute, otherwise, we're good to go.
    if (self.status_state_changed? && ((self.status_state == 4 || self.status_state == 5) || (self.status_state == 1 && self.current_response.nil?))) || self.is_private_changed? || self.body_changed? || self.title_changed?
      Sunspot.index(self)
    end
  end

  def generate_fingerprint
    create_time = Time.now.to_s
    self.question_fingerprint = Digest::MD5.hexdigest(create_time + self.body.to_s + self.email)
  end
  
  def set_last_opened
    self.last_opened_at = Time.now
  end
  
  def pick_user_from_list(users)
    if !users or users.length == 0
      return nil
    end

    # look at question assignments to see who has the least for load balancing
    users.sort! { |a, b| a.open_questions.length <=> b.open_questions.length }

    questions_floor = users[0].open_questions.length

    # who all matches the least amt. of questions assigned
    possible_users = users.select { |u| u.open_questions.length == questions_floor }

    return nil if !possible_users or possible_users.length == 0
    return possible_users[0] if possible_users.length == 1

    # if all possible question assignees with least amt. of questions assigned have zero questions assigned to them...
    # so if all experts that made the cut have zero questions assigned, pick a random person in that group to assign to
    if questions_floor == 0
      return possible_users.sample 
    end

    assignment_dates = Hash.new

    # for all those eligible experts with greater than zero questions assigned (but are in the group with the lowest number of questions assigned),
    # select the expert who's last assigned question was the earliest so that the ones with the more recent assigned questions do not get 
    # the next one
    possible_users.each do |u|
      question = u.open_questions.find(:first, :conditions => ["event_state = ?", QuestionEvent::ASSIGNED_TO], :include => :question_events, :order => "question_events.created_at desc")

      if question
        assignment_dates[u.id] = question.question_events[0].created_at
      # shouldn't happen b/c the case of no questions assigned is covered above
      else
        assignment_dates[u.id] = Time.at(0)
      end
    end

    user_id = assignment_dates.sort{ |a, b| a[1] <=> b[1] }[0][0]

    return User.find(user_id)
  end
  
  def notify_submitter
    if(!self.spam?)
      Notification.create(notifiable: self, created_by: 1, recipient_id: self.submitter.id, notification_type: Notification::AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT, delivery_time: 1.minute.from_now ) unless self.submitter.nil? or self.submitter.id.nil?
    end
  end
  
  def send_global_widget_notifications
    if(!self.spam?)
      Notification.create(notifiable: self, created_by: 1, recipient_id: 1, notification_type: Notification::AAE_ASSIGNMENT_GROUP, delivery_time: 1.minute.from_now )  unless self.assigned_group.nil? or self.assigned_group.incoming_notification_list.empty? #group notification
    end
  end
  

  def is_answered?
    self.status_state == STATUS_RESOLVED
  end

  def create_evaluation_notification
    if(self.is_answered? and !self.submitter.answered_evaluation_for_question?(self))
      Notification.create(notifiable: self, created_by: self.submitter.id, recipient_id: self.submitter.id, notification_type: Notification::AAE_PUBLIC_EVALUATION_REQUEST, delivery_time: 1.minute.from_now )
    end
  end

  def self.evaluation_pool(days_closed = Settings.days_closed_for_evaluation)
    with_scope do
      self.answered.where(evaluation_sent: false).where('DATE(resolved_at) = ?',Date.today - days_closed)
    end
  end

  def response_time(initial_only = false)
    response_count = self.responses.expert.count
    followup_response_count = self.responses.expert_after_public.count
    if(response_count == 1 or initial_only)
      self.initial_response_time
    elsif(response_count > 1)
      if(followup_response_count >= 1)
        self.responses.expert_after_public.average(:time_since_last).round
      else
        self.initial_response_time
      end
    else
      nil
    end
  end

  def question_activity_preference_list
    list = Preference.where(name: 'notification.question.activity',question_id: self.id )
  end
  
  # Reports Stuff
  
  def self.answered_list_for_year_month(year_month)
    year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
    with_scope do
      question_id_records = self.joins(:question_events)
      .where("question_events.event_state = #{QuestionEvent::RESOLVED}")
      .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month).pluck(:question_id)
    
      if question_id_records.length > 0
        return Question.where("id IN (#{question_id_records.join(',')})")
      else
        return Question.none
      end
    end
  end
  
  def self.resolved_response_list_for_year_month(year_month)
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      self.select("question_events.*").joins(:question_events)
        .where("question_events.event_state = #{QuestionEvent::RESOLVED}")
        .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month)
    end
  end
  
  def self.resolved_response_initiators_for_year_month(year_month)
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      self.select("DISTINCT(question_events.initiated_by_id)").joins(:question_events)
        .where("question_events.event_state = #{QuestionEvent::RESOLVED}")
        .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month)
    end
  end
  
  def self.asked_list_for_year_month(year_month)
    year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
    
    self.where("DATE_FORMAT(questions.created_at,'#{date_string}') = ?",year_month)
  end
  
  def self.resolved_questions_by_in_state_responders(location, year_month)
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      question_id_records = self.joins(:question_events => :initiator)
        .where("users.location_id = ?", location.id)
        .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?", year_month)
        .where("question_events.event_state = #{QuestionEvent::RESOLVED}").pluck(:question_id)
      
      if question_id_records.count > 0    
        return Question.where("id IN (#{question_id_records.join(',')})")
      else
        return Question.none
      end
    end
  end
  
  def self.responses_by_in_state_responders(location, year_month)
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      self.select("question_events.*").joins(:question_events => :initiator)
        .where("users.location_id = ?", location.id)
        .where("question_events.event_state = #{QuestionEvent::RESOLVED}")
        .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month)
    end
  end
  
  def self.resolved_questions_by_outside_state_responders(location, year_month)
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      question_id_records = Question.joins(:question_events => :initiator)
        .where("users.location_id IS NULL OR users.location_id <> ?", location.id)
        .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?", year_month)
        .where("question_events.event_state = #{QuestionEvent::RESOLVED}").pluck(:question_id)
      if question_id_records.count > 0  
        return Question.where("id IN (#{question_id_records.join(',')})")
      else
        return Question.none
      end
    end
  end
  
  def self.responses_by_outside_state_responders(location, year_month)
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      self.select("question_events.*").joins(:question_events => :initiator)
        .where("users.location_id IS NULL OR users.location_id <> ?", location.id)
        .where("question_events.event_state = #{QuestionEvent::RESOLVED}")
        .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month)
    end
  end
    
end
