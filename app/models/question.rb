class Question < ActiveRecord::Base
  has_many :images, :as => :assetable, :class_name => "Question::Image", :dependent => :destroy
  belongs_to :assignee, :class_name => "User", :foreign_key => "assignee_id"
  belongs_to :current_resolver, :class_name => "User"
  belongs_to :location
  belongs_to :county
  belongs_to :widget 
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  belongs_to :assigned_group, :class_name => "Group", :foreign_key => "assigned_group_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  belongs_to :contributing_question, :class_name => "Question", :foreign_key => "contributing_question_id"
  
  has_many :comments
  has_many :ratings
  has_many :responses
  has_many :question_events
  
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  
  accepts_nested_attributes_for :images
  accepts_nested_attributes_for :responses
  
  validates :body, :presence => true
  validates :submitter_email, :presence => true, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  
  before_create :generate_fingerprint, :clean_question_and_answer, :set_last_opened
  before_update :clean_question_and_answer

  after_create :auto_assign_by_preference, :notify_submitter, :send_global_widget_notifications
  
  scope :public_visible, conditions: { is_private: false }
  scope :from_group, lambda {|group_id| {:conditions => {:assigned_group_id => group_id}}}
  scope :tagged_with, lambda {|tag_id| 
    {:include => {:taggings => :tag}, :conditions => "tags.id = '#{tag_id}' AND taggings.taggable_type = 'Question'"}
  }

  # sunspot/solr search
  searchable do
    text :title, more_like_this: true
    text :body, more_like_this: true
    text :response_list, more_like_this: true
    integer :status_state
    boolean :spam
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
   4 => "private because of spam/offensive",
   5 => "private because of rejected/duplicate"
  }
  
  # privacy constants
  PRIVACY_REASON_PUBLIC = 1
  PRIVACY_REASON_SUBMITTER = 2
  PRIVACY_REASON_EXPERT = 3
  PRIVACY_REASON_SPAM = 4
  PRIVACY_REASON_REJECTED = 5
  
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
  
  DECLINE_ANSWER = "Thank you for your question for eXtension. The topic area in which you've made a request is not yet fully staffed by eXtension experts and therefore we cannot provide you with a timely answer. Instead, if you live in the United States, please consider contacting the Cooperative Extension office closest to you. Simply go to http://www.extension.org, drop in your zip code and choose the local office in your neighborhood. We apologize for this inconvenience but please come back to eXtension to check in as we grow and add experts."
  
  # for purposes of solr search
  def response_list
    self.responses.map(&:body).join(' ')
  end
  
  def auto_assign_by_preference
    if existing_question = Question.find(:first, :conditions => ["id != #{self.id} and body = ? and submitter_email = '#{self.submitter_email}'", self.body])
      reject_msg = "This question was a duplicate of incoming question ##{existing_sq.id}"
      self.add_resolution(STATUS_REJECTED, User.system_user, reject_msg)
      return
    end

    if Settings.auto_assign_incoming_questions
      auto_assign
    end
  end
  
  def auto_assign
    assignee = nil
    
    group = self.assigned_group
    if (group.assignment_outside_locations || group.expertise_locations.include?(self.location)) && group.assignees.length > 0
      if self.county.present?
        assignee = pick_user_from_list(group.assignees.with_expertise_county(self.county.id))
      end
      if !assignee && self.location.present?
        assignee = pick_user_from_list(group.assignees.with_expertise_location(self.location.id))
      end
      if !assignee 
        group_assignee_ids = group.assignees.collect{|ga| ga.id}
        assignee = pick_user_from_list(group.assignees.can_route_outside_location(group_assignee_ids))
      end
      # still aint got no one? wrangle that bad boy.
      if !assignee
        assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county))
      end
    else
      # send to the question wrangler group if the location of the question is not in the location of the group and 
      # the group is not receiving questions from outside their defined locations.
      assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county))
    end
    
    if assignee
      system_user = User.system_user
      assign_to(assignee, system_user, nil)
    else
      return
    end
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
      asker_comment = public_comment.response
    else
      asker_comment = nil
    end
    
    # TODO: Put New Notification Logic Here
    # create notifications
    # Notification.create(:notifytype => Notification::AAE_ASSIGNMENT, :account => user, :creator => assigned_by, :additionaldata => {:submitted_question_id => self.id, :comment => comment, :asker_comment => asker_comment})
    #     if(is_reassign and public_reopen == false)
    #       Notification.create(:notifytype => Notification::AAE_REASSIGNMENT, :account => previously_assigned_to, :creator => assigned_by, :additionaldata => {:submitted_question_id => self.id})
    #     end
  end
  
  # updates the question, creates a response and  
  # calls the function to log a new resolved question event 
  def add_resolution(q_status, resolver, response, signature = nil, contributing_question = nil)

    t = Time.now

    case q_status
      when STATUS_RESOLVED    
        self.update_attributes(:status => Question.convert_to_string(q_status), :status_state =>  q_status, :current_resolver => resolver, :current_response => response, :current_resolver_email => resolver.email, :contributing_question => contributing_question, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
        @response = Response.new(:resolver => resolver, 
                                 :question => self, 
                                 :body => response,
                                 :sent => true, 
                                 :contributing_question => contributing_question, 
                                 :signature => signature)
        @response.save
        QuestionEvent.log_resolution(self)    
      when STATUS_NO_ANSWER
        self.update_attributes(:status => Question.convert_to_string(q_status), :status_state =>  q_status, :current_resolver => resolver, :current_response => response, :current_resolver_email => resolver.email, :contributing_question => contributing_question, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
        @response = Response.new(:resolver => resolver, 
                                 :question => self, 
                                 :body => response, 
                                 :sent => true, 
                                 :contributing_question => contributing_question, 
                                 :signature => signature)
        @response.save
        QuestionEvent.log_no_answer(self)  
      when STATUS_REJECTED
        self.update_attributes(:status => Question.convert_to_string(q_status), :status_state => q_status, :current_response => response, :current_resolver => resolver, :current_resolver_email => resolver.email, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"), :is_private => true, :is_private_reason => PRIVACY_REASON_REJECTED)
        QuestionEvent.log_rejection(self)
    end
  end
  
  # for the 'Hand off to a Question Wrangler' functionality
  def assign_to_question_wrangler(assigned_by)
    assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county))
    comment = WRANGLER_REASSIGN_COMMENT

    assign_to(assignee, assigned_by, comment)
    self.assigned_group = Group.question_wrangler_group
    self.save
    return assignee
  end
  
  def resolved?
    !self.status_state == STATUS_SUBMITTED
  end
  
  # utility function to convert status_state numbers to status strings
  def self.convert_to_string(status_number)
    case status_number
    when STATUS_SUBMITTED
      return 'submitted'
    when STATUS_RESOLVED
      return 'resolved'
    when STATUS_NO_ANSWER
      return 'no answer'
    when STATUS_REJECTED
      return 'rejected'
    else
      return nil
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
    if self.tags.collect{|t| t.name}.include?(Tag.normalizename(tag))
      return false
    else 
      if(tag = Tag.find_or_create_by_name(Tag.normalizename(tag)))
        self.tags << tag
        return tag
      end
    end
  end
  
  private

  def generate_fingerprint
    create_time = Time.now.to_s
    self.question_fingerprint = Digest::MD5.hexdigest(create_time + self.body.to_s + self.submitter_email)
  end
  
  # TODO: probably needs to be changed, not sure to what yet.
  def clean_question_and_answer  
    # if self.current_response and self.current_response.strip != ''
    #       self.current_response = Hpricot(self.current_response.sanitize).to_html 
    #     end
    # 
    #     self.asked_question = Hpricot(self.asked_question.sanitize).to_html
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
  
  # TODO: setup notifications here
  def notify_submitter
    return
  end
  
  # TODO: setup notifications here
  def send_global_widget_notifications
    return
  end
  
  class Question::Image < Asset
    has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  end
  
    
end
