class Question < ActiveRecord::Base
  has_many :images, :as => :assetable, :class_name => "Response::Image", :dependent => :destroy
  belongs_to :assignee, :class_name => "User", :foreign_key => "assignee_id"
  belongs_to :current_resolver, :class_name => "User"
  belongs_to :location
  belongs_to :county
  belongs_to :widget 
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  belongs_to :assigned_group, :class_name => "Group", :foreign_key => "assigned_group_id"
  
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
    integer :status_states, :multiple => true
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
    
    ##############################################################################################
    group = self.group
    if group.assignment_outside_locations || group.expertise_locations.include?(self.location)
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
        wrangler_group = Group.find_by_id(Group::QUESTIONWRANGLERID)
        assignee = pick_user_from_list(qw_group.assignees)
      end
    else
      # send to the question wrangler group if the location of the question is not in the location of the group and 
      # the group is not receiving questions from outside their defined locations.
      assignee = pick_user_from_list(qw_group.assignees)
    end
    
    
    ##############################################################################################
    
    # first, check to see if it's from a named widget 
    # and route accordingly
    if widget = self.widget
      assignee = pick_user_from_list(widget.assignees)
    end

    if !assignee
      if !self.categories || self.categories.length == 0
        question_categories = nil
      else
        question_categories = self.categories
        parent_category = question_categories.detect{|c| !c.parent_id}
      end

      # if a state and county were provided when the question was asked
      # update: if there is location data supplied and there is not a category 
      # associated with the question, then route to the uncategorized question wranglers 
      # that chose that location or county in their location preferences
      if self.county and self.location
        assignee = pick_user_from_county(self.county, question_categories) 
      #if a state and no county were provided when the question was asked
      elsif self.location
        assignee = pick_user_from_state(self.location, question_categories)
      end
    end

    # if a user cannot be found yet...
    if !assignee
      if !question_categories
        # if no category, wrangle it
        assignee = pick_user_from_list(User.uncategorized_wrangler_routers)
      else
        # got category, first, look for a user with specified category
        assignee = pick_user_from_category(question_categories)
        # still ain't got no one? send to the wranglers to wrangle
        assignee = pick_user_from_list(User.uncategorized_wrangler_routers) if not assignee
      end  
    end

    if assignee
      systemuser = User.systemuser
      assign_to(assignee, systemuser, nil)
    else
      return
    end
  end
  
  
  
  
  
  
  
  
  
  # updates the question, creates a response and  
  # calls the function to log a new resolved question event 
  def add_resolution(q_status, resolver, response, signature = nil, contributing_content = nil)

    t = Time.now

    case q_status
      when STATUS_RESOLVED    
        self.update_attributes(:status => Question.convert_to_string(q_status), :status_state =>  q_status, :resolved_by => resolver, :current_response => response, :resolver_email => resolver.email, :contributing_content => contributing_content, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
        @response = Response.new(:resolver => resolver, 
                                 :question => self, 
                                 :body => response,
                                 :sent => true, 
                                 :contributing_content => contributing_content, 
                                 :signature => signature)
        @response.save
        QuestionEvent.log_resolution(self)    
      when STATUS_NO_ANSWER
        self.update_attributes(:status => Question.convert_to_string(q_status), :status_state =>  q_status, :resolved_by => resolver, :current_response => response, :resolver_email => resolver.email, :contributing_content => contributing_content, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
        @response = Response.new(:resolver => resolver, 
                                 :submitted_question => self, 
                                 :body => response, 
                                 :sent => true, 
                                 :contributing_content => contributing_content, 
                                 :signature => signature)
        @response.save
        QuestionEvent.log_no_answer(self)  
      when STATUS_REJECTED
        self.update_attributes(:status => Question.convert_to_string(q_status), :status_state => q_status, :current_response => response, :resolved_by => resolver, :resolver_email => resolver.email, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"), :show_publicly => false, :is_private => true)
        QuestionEvent.log_rejection(self)
    end

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
  
  
  
  private

  def generate_fingerprint
    create_time = Time.now.to_s
    self.question_fingerprint = Digest::MD5.hexdigest(create_time + self.body + self.submitter_email)
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
      return possible_users.rand 
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
  
    
end
