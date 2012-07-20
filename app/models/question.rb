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
    if existing_qusetion = Question.find(:first, :conditions => ["id != #{self.id} and body = ? and submitter_email = '#{self.submitter_email}'", self.body])
      reject_msg = "This question was a duplicate of incoming question ##{existing_sq.id}"
      self.add_resolution(STATUS_REJECTED, User.systemuser, reject_msg)
      return
    end

    if AppConfig.configtable['auto_assign_incoming_questions']
      auto_assign
    end
  end
  
  # updates the question, creates a response and  
  # calls the function to log a new resolved submitted question event 
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
        self.update_attributes(:status => Question.convert_to_string(sq_status), :status_state =>  q_status, :resolved_by => resolver, :current_response => response, :resolver_email => resolver.email, :contributing_content => contributing_content, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
        @response = Response.new(:resolver => resolver, 
                                 :submitted_question => self, 
                                 :response => response, 
                                 :sent => true, 
                                 :contributing_content => contributing_content, 
                                 :signature => signature)
        @response.save
        QuestionEvent.log_no_answer(self)  
      when STATUS_REJECTED
        self.update_attributes(:status => Question.convert_to_string(sq_status), :status_state => q_status, :current_response => response, :resolved_by => resolver, :resolver_email => resolver.email, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"), :show_publicly => false)
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
    
end
