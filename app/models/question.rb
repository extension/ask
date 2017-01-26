# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Question < ActiveRecord::Base
  # subclasses
  class Question::Image < Asset
    has_attached_file :attachment,
                      :url => "/uploads/:class/:attachment/:id_partition/:basename_:style.:extension",
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
        { :original => resize, :medium => "300x300>", :thumb => "100x100>" }
      end
    end

    def dynamic_attachment_url(format)
      @dynamic_style_format = format
      attachment.reprocess!(dynamic_style_format_symbol) unless attachment.exists?(dynamic_style_format_symbol)
      attachment.url(dynamic_style_format_symbol)
    end

    def resize
      # resize all images to a reasonable file size and so paperclip can fix orientation
      "4800x4800>"
    end
  end

  ## includes
  include MarkupScrubber
  include Rakismet::Model
  include CacheTools
  include TagUtilities
  extend NilUtils
  extend YearWeek

  ## attributes
  serialize :cached_tag_hash
  rakismet_attrs :author_email => :email, :content => :body
  has_paper_trail :on => [:update], :only => [:title, :body]

  # remove extra whitespace on these attributes
  auto_strip_attributes :submitter_email, :submitter_firstname, :submitter_lastname, :squish => true

  # sunspot/solr search
  searchable :auto_index => false do
    text :title, more_like_this: true
    text :body, more_like_this: true
    text :response_list, more_like_this: true
    integer :status_state
    boolean :is_private
  end


  ## constants
  ACCOUNT_REVIEW_REQUEST_TITLE = 'Account Review Request'
  TITLE_MAX_LENGTH = 100

  # status numbers (for status_state)
  STATUS_SUBMITTED = 1
  STATUS_RESOLVED = 2
  STATUS_NO_ANSWER = 3
  STATUS_REJECTED = 4
  STATUS_CLOSED = 5

  # status text (to be used when a text version of the status is needed)
  STATUS_TEXT = {
    STATUS_SUBMITTED => 'submitted',
    STATUS_RESOLVED => 'answered',
    STATUS_NO_ANSWER => 'not_answered',
    STATUS_REJECTED => 'rejected',
    STATUS_CLOSED => 'closed'
  }

  # privacy constants
  PRIVACY_REASON_PUBLIC = 1
  PRIVACY_REASON_SUBMITTER = 2
  PRIVACY_REASON_EXPERT = 3
  PRIVACY_REASON_REJECTED = 4

  # privacy reasons
  PRIVACY_CODE_TO_TEXT = {
   PRIVACY_REASON_PUBLIC => "public",
   PRIVACY_REASON_SUBMITTER => "private by submitter",
   PRIVACY_REASON_EXPERT => "private by expert",
   PRIVACY_REASON_REJECTED => "private because of rejected/duplicate"
  }



  DEFAULT_SUBMITTER_NAME = "Anonymous Guest"

  WRANGLER_REASSIGN_COMMENT = <<-END_TEXT.gsub(/\s+/, " ").strip
  This question has been assigned to you because the previous assignee
  clicked the 'Hand off to a Question Wrangler' button.
  END_TEXT

  PUBLIC_RESPONSE_REASSIGNMENT_COMMENT = <<-END_TEXT.gsub(/\s+/, " ").strip
  This question has been reassigned to you because a new comment has
  been posted to your response. Please reply using the link below or
  close the question out if no reply is needed. Thank You.
  END_TEXT

  PUBLIC_RESPONSE_REASSIGNMENT_BACKUP_COMMENT = <<-END_TEXT.gsub(/\s+/, " ").strip
  This question has been assigned to you because the submitter posted a new
  comment and the previously assigned expert is not available. Please reply
  using the link below or close the question out if no reply is needed. Thank You.
  END_TEXT

  DECLINE_ANSWER = <<-END_TEXT.gsub(/\s+/, " ").strip
  Thank you for your question for eXtension. The topic area in which
  you've made a request is not yet fully staffed by eXtension experts
  and therefore we cannot provide you with a timely answer. Instead,
  if you live in the United States, please consider contacting the
  Cooperative Extension office closest to you. Simply go to
  http://articles.extension.org, drop in your zip code and choose the
  office that is most convenient for you.  We apologize that we
  can't help you right now,  but please come back to eXtension to
  check in as we grow and add experts.
  END_TEXT

  # reporting scopes
  YEARWEEK_SUBMITTED = 'YEARWEEK(questions.created_at,3)'
  YEARWEEK_ANSWERED = 'YEARWEEK(questions.initial_response_at,3)'

  AAE_V2_TRANSITION = '2012-12-03 12:00:00 UTC'
  DEMOGRAPHIC_ELIGIBLE = '2012-12-03 12:00:00 UTC'
  EVALUATION_ELIGIBLE = '2013-03-15 00:00:00 UTC' # beware the ides of March

  ## associations
  has_many :images, :as => :assetable, :class_name => "Question::Image", :dependent => :destroy
  accepts_nested_attributes_for :images, :allow_destroy => true
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
  belongs_to :initial_response,  class_name: 'Response', :foreign_key => "initial_response_id"
  belongs_to :initial_responder, :class_name => "User", :foreign_key => "initial_responder_id"

  has_many :ratings
  has_many :responses
  accepts_nested_attributes_for :responses
  has_many :question_events
  has_many :question_viewlogs, dependent: :destroy
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  has_many :evaluation_answers, class_name: 'EvaluationAnswer', foreign_key: 'question_id'
  has_one :question_data_cache

  ## scopes
  scope :public_visible, conditions: { is_private: false }
  scope :not_public_visible, conditions: { is_private: true }
  scope :switched_to_private, conditions: { is_private: true, :is_private_reason => PRIVACY_REASON_EXPERT}
  scope :public_visible_answered, conditions: { is_private: false, :status_state => STATUS_RESOLVED }
  scope :public_visible_unanswered, conditions: { is_private: false, :status_state => STATUS_SUBMITTED }
  scope :public_visible_with_images_answered, :include => :images, :conditions => "assets.id IS NOT NULL AND is_private = false AND status_state = #{STATUS_RESOLVED}"
  scope :public_visible_with_images_unanswered, :include => :images, :conditions => "assets.id IS NOT NULL AND is_private = false AND status_state = #{STATUS_SUBMITTED}"
  scope :from_group, lambda {|group_id| {:conditions => {:assigned_group_id => group_id}}}
  scope :tagged_with, lambda {|tag_id|
    {:include => {:taggings => :tag}, :conditions => "tags.id = '#{tag_id}' AND taggings.taggable_type = 'Question'"}
  }
  # both tagged_with_all and tagged_with_any are expecting arrays of tag strings
  scope :tagged_with_all, lambda{|tag_list|
    joins(:tags).where("tags.name IN (#{tag_list.map{|t| "'#{Tag.normalizename(t)}'"}.join(',')})").group("questions.id").having("COUNT(questions.id) = #{tag_list.size}")
  }
  scope :tagged_with_any, lambda { |tag_list|
    joins(:tags).where("tags.name IN (#{tag_list.map{|t| "'#{Tag.normalizename(t)}'"}.join(',')})").group("questions.id")
  }
  scope :by_location, lambda {|location| {:conditions => {:location_id => location.id}}}
  scope :by_county, lambda {|county| {:conditions => {:county_id => county.id}}}
  scope :answered, ->{ where(status_state: STATUS_RESOLVED) }
  scope :submitted, ->{ where(status_state: STATUS_SUBMITTED) }
  scope :not_rejected, ->{ where("status_state <> #{STATUS_REJECTED}") }
  # special scope for returning an empty AR association
  scope :none, where('1 = 0')


  scope :public_submissions, lambda { where(submitter_is_extension: false) }
  scope :evaluation_eligible, lambda { where("questions.created_at >= ?",Time.parse(EVALUATION_ELIGIBLE)).where(evaluation_sent: true) }
  scope :demographic_eligible, lambda { where("questions.created_at >= ?",Time.parse(DEMOGRAPHIC_ELIGIBLE)).where(evaluation_sent: true) }


  ## validations
  validates :body, :presence => true
  validates_length_of :body, :maximum => 10000, :message => "Too Long"
  validate :validate_attachments

  ## filters
  before_create :generate_fingerprint, :set_last_opened, :set_is_extension
  after_create :reject_if_spam_or_duplicate, :queue_initial_assignment, :notify_submitter, :index_me
  after_update :index_me
  after_save :update_data_cache

  ## class methods
  def self.evaluation_pool(days_closed = Settings.days_closed_for_evaluation)
    # we need to count every non rejected question with at least one response
    self.answered
        .where("questions.created_at >= ?",Time.parse(EVALUATION_ELIGIBLE))
        .where(evaluation_sent: false)
        .where('DATE(resolved_at) <= ?',Date.today - days_closed)
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


  # Reports Stuff
  def self.answered_list_for_year_month(year_month)
    year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
    with_scope do
      question_id_records = self.joins(:question_events)
      .where("question_events.event_state = #{QuestionEvent::RESOLVED}")
      .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month).pluck('questions.id')

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
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      self.where("DATE_FORMAT(questions.created_at,'#{date_string}') = ?",year_month)
    end
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

  def self.resolved_questions_by_in_state_responders_outside_location(location, year_month)
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      question_id_records = self.joins(:question_events => :initiator)
        .where("users.location_id = ?", location.id)
        .where("questions.location_id IS NULL OR questions.location_id <> ?", location.id)
        .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?", year_month)
        .where("question_events.event_state = #{QuestionEvent::RESOLVED}").pluck(:question_id)

      if question_id_records.count > 0
        return Question.where("id IN (#{question_id_records.join(',')})")
      else
        return Question.none
      end
    end
  end

  def self.responses_by_in_state_responders_outside_location(location, year_month)
    with_scope do
      year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
      self.select("question_events.*").joins(:question_events => :initiator)
        .where("users.location_id = ?", location.id)
        .where("questions.location_id IS NULL OR questions.location_id <> ?", location.id)
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

  # making a separate method for this right now using memcache, but may combine with similar function for this later
  def self.cached_asked_for_year_month(year_month, cache_options = { expires_in: 2.hours })
    cache_key = self.get_cache_key(__method__, { year_month: year_month })
    Rails.cache.fetch(cache_key, cache_options) do
      self.not_rejected.asked_list_for_year_month(year_month).count
    end
  end

  # making a separate method for this right now using memcache, but may combine with similar function for this later
  def self.cached_answered_for_year_month(year_month, cache_options = { expires_in: 2.hours })
    cache_key = self.get_cache_key(__method__, { year_month: year_month })
    Rails.cache.fetch(cache_key, cache_options) do
      self.not_rejected.answered_list_for_year_month(year_month).count
    end
  end

  def self.in_state_out_metrics_by_year(year,cache_options = {})
    if(!cache_options[:expires_in].present?)
      if(year == Date.today.year)
        cache_options[:expires_in] = 24.hours
      else
        cache_options[:expires_in] = 7.days
      end
    end
    cache_key = self.get_cache_key(__method__,{year: year})
    Rails.cache.fetch(cache_key,cache_options) do
      self._in_state_out_metrics_by_year(year)
    end
  end

  def self.asked_answered_metrics_by_year(year,cache_options = {})
    if(!cache_options[:expires_in].present?)
      if(year == Date.today.year)
        cache_options[:expires_in] = 24.hours
      else
        cache_options[:expires_in] = 7.days
      end
    end
    cache_key = self.get_cache_key(__method__,{year: year})
    Rails.cache.fetch(cache_key,cache_options) do
      self._asked_answered_metrics_by_year(year)
    end
  end

  def self._in_state_out_metrics_by_year(year)
    in_out_state = {}
    out_state = Question.not_rejected.joins(:question_events => :initiator) \
                .where('users.location_id != questions.location_id') \
                .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
                .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
                .count('DISTINCT(questions.id)')

    out_state_experts = Question.not_rejected.joins(:question_events => :initiator) \
                .where('users.location_id != questions.location_id') \
                .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
                .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
                .count('DISTINCT(question_events.initiated_by_id)')

    in_state = Question.not_rejected.joins(:question_events => :initiator) \
                .where('users.location_id = questions.location_id') \
                .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
                .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
                .count('DISTINCT(questions.id)')

    in_state_experts = Question.not_rejected.joins(:question_events => :initiator) \
                .where('users.location_id = questions.location_id') \
                .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
                .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
                .count('DISTINCT(question_events.initiated_by_id)')

      in_out_state = {:in_state => in_state || 0,
                      :out_state => out_state || 0,
                      :in_state_experts => in_state_experts || 0,
                      :out_state_experts => out_state_experts || 0 }

  end

  def self._asked_answered_metrics_by_year(year)
    asked_answered = {}
    asked    = Question.not_rejected \
               .where("DATE_FORMAT(questions.created_at,'%Y') = #{year}") \
               .count('DISTINCT(questions.id)')

    submitters = Question.not_rejected \
               .where("DATE_FORMAT(questions.created_at,'%Y') = #{year}") \
               .count('DISTINCT(questions.submitter_id)')

    answered = Question.not_rejected.joins(:question_events => :initiator) \
               .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
               .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
               .count('DISTINCT(questions.id)')

    experts = QuestionEvent.joins(:initiator).handling_events \
               .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
               .count('DISTINCT(question_events.initiated_by_id)')

      asked_answered = {:asked => asked || 0,
                        :submitters => submitters|| 0,
                        :answered => answered|| 0,
                        :experts => experts|| 0 }

    asked_answered

  end

  def self.asked_answered_metrics_for_date_range(start_date,end_date)
    asked_answered = {}
    asked    = Question.not_rejected \
               .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
               .count('DISTINCT(questions.id)')

    submitters = Question.not_rejected \
               .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
               .count('DISTINCT(questions.submitter_id)')

    answered = Question.not_rejected.joins(:question_events => :initiator) \
               .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
               .where("DATE(question_events.created_at) >= ? and DATE(question_events.created_at) <= ?",start_date.to_s,end_date.to_s)
               .count('DISTINCT(questions.id)')

    experts = QuestionEvent.joins(:initiator).handling_events \
    .where("DATE(question_events.created_at) >= ? and DATE(question_events.created_at) <= ?",start_date.to_s,end_date.to_s)
               .count('DISTINCT(question_events.initiated_by_id)')

      asked_answered = {:asked => asked || 0,
                        :submitters => submitters|| 0,
                        :answered => answered|| 0,
                        :experts => experts|| 0 }

    asked_answered

  end

  def self.expert_submitter_metrics_for_date_range(start_date,end_date)
    expert_ids = QuestionEvent.joins(:initiator).handling_events \
    .where("DATE(question_events.created_at) >= ? and DATE(question_events.created_at) <= ?",start_date.to_s,end_date.to_s) \
    .pluck('question_events.initiated_by_id').uniq
    previous_expert_ids = QuestionEvent.joins(:initiator).handling_events \
    .where("DATE(question_events.created_at) <= ?",start_date.to_s) \
    .pluck('question_events.initiated_by_id').uniq
    submitter_ids = Question.not_rejected \
               .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
               .pluck('questions.submitter_id')
    previous_submitter_ids = Question.not_rejected \
              .where("DATE(questions.created_at) <= ?",start_date.to_s) \
              .pluck('questions.submitter_id')

              {:experts => expert_ids.size || 0,
                                :new_experts => (expert_ids - previous_expert_ids).size || 0,
                                :submitters => submitter_ids.size|| 0,
                                :new_submitters => (submitter_ids - previous_submitter_ids).size|| 0 }

  end


  ## instance methods



  # for purposes of solr search
  def response_list
    self.responses.map(&:body).join(' ')
  end

  # get resolvers for a question
  def resolver_list
    self.responses.map{|r| r.resolver}.uniq.compact
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

  def check_for_duplicate
    Question.joins(:submitter).where("questions.id != ?",self.id).where(body: self.body).where("users.email = ?",self.email).first
  end


  def is_being_worked_on?
    if !self.working_on_this.nil?
      if self.working_on_this > Time.zone.now
        return true
      else
        return false
      end
    end
    return false
  end

  def title
    if self[:title].present?
      return self[:title].gsub(/[[:space:]]/, ' ')
    else
      return self.html_to_text(self[:body].squish).truncate(80, separator: ' ').gsub(/[[:space:]]/, ' ')
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



  def find_group_assignee(assignees_to_exclude = nil)
    assignee_tests = []
    group = self.assigned_group
    if(assignees_to_exclude.present?)
      base_assignee_scope = group.assignees.where("users.id NOT IN (#{assignees_to_exclude.map(&:id).join(',')})")
    else
      base_assignee_scope = group.assignees
    end

    if(base_assignee_scope.count  == 0)
      # no one is home, wrangle it
      assignee_tests << AutoAssignmentLog::WRANGLER_HANDOFF_EMPTY_GROUP

      # find a wrangler
      results = find_question_wrangler(assignees_to_exclude)
      return { assignee: results[:assignee],
               user_pool:  results[:user_pool],
               wrangler_assignment_code: AutoAssignmentLog::WRANGLER_HANDOFF_EMPTY_GROUP,
               assignment_code: results[:assignment_code],
               assignee_tests: assignee_tests + results[:assignee_tests] }
    end

    if(self.location_id.present?)
      if(group.ignore_county_routing?)
        # group setting overrides county constraint - get a location match
        assignee_pool = base_assignee_scope.with_expertise_location(self.location_id)
        assignee_tests << AutoAssignmentLog::LOCATION_MATCH_GROUP_IGNORES_COUNTY
        assignee = User.pick_assignee_from_pool(assignee_pool)
        if(assignee)
          return { assignee: assignee,
                   user_pool:  AutoAssignmentLog.mapped_user_pool(assignee_pool),
                   assignment_code: AutoAssignmentLog::LOCATION_MATCH_GROUP_IGNORES_COUNTY,
                   assignee_tests: assignee_tests }
        end
      else
        if self.county_id.present?
          # get a location + county match
          assignee_pool = base_assignee_scope.with_expertise_county(self.county_id)
          assignee_tests << AutoAssignmentLog::COUNTY_MATCH
          assignee = User.pick_assignee_from_pool(assignee_pool)
          if(assignee)
            return { assignee: assignee,
                     user_pool:  AutoAssignmentLog.mapped_user_pool(assignee_pool),
                     assignment_code: AutoAssignmentLog::COUNTY_MATCH,
                     assignee_tests: assignee_tests }
          end
        end

        # get a location + "all" county match
        # this probably should also get the pool of people with any kind of location
        # match, as long as their routing instructions don't have a county specificity
        # but it was working and we didn't change it per Slack discussion on
        # 2016-06-15 - jayoung
        assignee_pool = base_assignee_scope.with_expertise_location_all_counties(self.location_id)
        assignee_tests << AutoAssignmentLog::LOCATION_MATCH_ALL_COUNTY
        assignee = User.pick_assignee_from_pool(assignee_pool)
        if(assignee)
          return { assignee: assignee,
                   user_pool:  AutoAssignmentLog.mapped_user_pool(assignee_pool),
                   assignment_code: AutoAssignmentLog::LOCATION_MATCH_ALL_COUNTY,
                   assignee_tests: assignee_tests }
        end
      end # no group override of county
    end # question has location

    # look for active anywhere
    assignee_pool = base_assignee_scope.route_from_anywhere
    assignee_tests << AutoAssignmentLog::ANYWHERE
    assignee = User.pick_assignee_from_pool(assignee_pool)
    if(assignee)
      return { assignee: assignee,
               user_pool:  AutoAssignmentLog.mapped_user_pool(assignee_pool),
               assignment_code: AutoAssignmentLog::ANYWHERE,
               assignee_tests: assignee_tests }
    end

    # fallback to not away leaders, whether they auto route or not
    if(assignees_to_exclude.present?)
      assignee_pool = group.leaders.not_away.where("users.id NOT IN (#{assignees_to_exclude.map(&:id).join(',')})")
    else
      assignee_pool = group.leaders.not_away
    end
    assignee_tests << AutoAssignmentLog::LEADER
    assignee = User.pick_assignee_from_pool(assignee_pool)
    if(assignee)
      return { assignee: assignee,
               user_pool:  AutoAssignmentLog.mapped_user_pool(assignee_pool),
               assignment_code: AutoAssignmentLog::LEADER,
               assignee_tests: assignee_tests }
    end


    # find a wrangler
    assignee_tests << AutoAssignmentLog::WRANGLER_HANDOFF_NO_MATCHES
    results = find_question_wrangler(assignees_to_exclude)

    return { assignee: results[:assignee],
             user_pool:  results[:user_pool],
             wrangler_assignment_code: AutoAssignmentLog::WRANGLER_HANDOFF_NO_MATCHES,
             assignment_code: results[:assignment_code],
             assignee_tests: assignee_tests + results[:assignee_tests] }

  end

  def find_question_wrangler(assignees_to_exclude = nil)
    assignee_tests = []
    wrangler_group = Group.question_wrangler_group

    if(assignees_to_exclude.present?)
      base_assignee_scope = wrangler_group.assignees.where("users.id NOT IN (#{assignees_to_exclude.map(&:id).join(',')})")
    else
      base_assignee_scope = wrangler_group.assignees
    end

    # check for county match, then location match, then anywhere

    # county
    if(self.county_id.present?)
      assignee_pool = base_assignee_scope.with_expertise_county(self.county_id)
      assignee_tests << AutoAssignmentLog::WRANGLER_COUNTY_MATCH
      assignee = User.pick_assignee_from_pool(assignee_pool)
      if(assignee)
        return { assignee: assignee,
                 user_pool:  AutoAssignmentLog.mapped_user_pool(assignee_pool),
                 assignment_code: AutoAssignmentLog::WRANGLER_COUNTY_MATCH,
                 assignee_tests: assignee_tests }
      end
    end

    # location
    if(self.location_id.present?)
      assignee_pool = base_assignee_scope.with_expertise_county(self.location_id)
      assignee_tests << AutoAssignmentLog::WRANGLER_LOCATION_MATCH
      assignee = User.pick_assignee_from_pool(assignee_pool)
      if(assignee)
        return { assignee: assignee,
                 user_pool:  AutoAssignmentLog.mapped_user_pool(assignee_pool),
                 assignment_code: AutoAssignmentLog::WRANGLER_LOCATION_MATCH,
                 assignee_tests: assignee_tests }
      end
    end

    # anywhere
    assignee_pool = base_assignee_scope.route_from_anywhere
    assignee_tests << AutoAssignmentLog::WRANGLER_ANYWHERE
    assignee = User.pick_assignee_from_pool(assignee_pool)
    if(assignee)
      return { assignee: assignee,
               user_pool:  AutoAssignmentLog.mapped_user_pool(assignee_pool),
               assignment_code: AutoAssignmentLog::WRANGLER_ANYWHERE,
               assignee_tests: assignee_tests }
    end

    # uh-oh!
    return { assignee: nil,
             user_pool:  {},
             assignment_code: AutoAssignmentLog::FAILURE,
             assignee_tests: assignee_tests }

  end

  # runs after creation
  def reject_if_spam_or_duplicate
    if(self.spam?)
      self.add_resolution(STATUS_REJECTED, User.system_user, 'Spam')
    elsif(self.has_blank_body_when_links_removed?)
      self.spam!
      self.add_resolution(STATUS_REJECTED, User.system_user, 'Spam')
    elsif existing_question = self.check_for_duplicate
      reject_msg = "This question is a duplicate of question ##{existing_question.id}"
      self.add_resolution(STATUS_REJECTED, User.system_user, reject_msg)
    end
    return true
  end

  def queue_initial_assignment
    return true if self.status_state != STATUS_SUBMITTED
    group = self.assigned_group

    if(!group.will_accept_question_location(self))
      reason = <<-END_TEXT.gsub(/\s+/, " ").strip
      The assigned group for this question #{group.name} does not accept
      questions outside its locations. Transferring to the Question Wrangler
      group.
      END_TEXT
      self.kick_out_to_wrangler_group(reason)
      group = Group.question_wrangler_group
    end

    if(!Settings.sidekiq_enabled)
      self.find_group_assignee_and_assign
    else
      self.class.delay_for(5.seconds).delayed_find_group_assignee_and_assign(self.id)
    end

    # queue a notification to the group
    if(!group.nil? and !group.incoming_notification_list.empty?)
      Notification.create(notifiable: self,
                          created_by: 1,
                          recipient_id: 1,
                          notification_type: Notification::AAE_ASSIGNMENT_GROUP,
                          delivery_time: 1.minute.from_now )
    end

  end

  def find_group_assignee_and_assign(assignees_to_exclude = nil)
    system_user = User.system_user
    group = self.assigned_group

    if(!group.individual_assignment?)
      QuestionEvent.log_group_assignment(self, group, system_user, nil)
      return true
    end

    # find
    results = self.find_group_assignee(assignees_to_exclude)

    # log auto assignment
    log = AutoAssignmentLog.log_assignment(results.merge(question: self, group: group))

    # assign_to
    assign_to(assignee: results[:assignee],
              assigned_by: system_user,
              comment: "Reason assigned: " + log.auto_assignment_reason,
              is_auto_assignment: true,
              auto_assignment_log: log)

  end

  def self.delayed_find_group_assignee_and_assign(question_id)
    if(question = find_by_id(question_id))
      question.find_group_assignee_and_assign
    end
  end

  def kick_out_to_wrangler_group(reason)
    question_wrangler_group = Group.question_wrangler_group
    current_assigned_group = self.assigned_group
    self.update_attributes(:assigned_group => question_wrangler_group, :assignee => nil, :working_on_this => nil)
    QuestionEvent.log_group_change(question: self, old_group: current_assigned_group, new_group: question_wrangler_group, initiated_by: User.system_user)
    QuestionEvent.log_group_assignment(self,question_wrangler_group,User.system_user,reason)
    true
  end

  def add_history_comment(user, comment)
    QuestionEvent.log_history_comment(self, user, comment)
  end

  # Assigns the question to the user, logs the assignment, and sends an email
  # to the assignee letting them know that the question has been assigned to
  # them.
  def assign_to(options = {})
    current_assignee = self.assignee
    assign_to = options[:assignee]
    assigned_by = options[:assigned_by]
    comment = options[:comment]
    submitter_reopen = options[:submitter_reopen].present? ? options[:submitter_reopen] : false
    resolving_self_assignment = options[:resolving_self_assignment].present? ? options[:resolving_self_assignment] : false
    auto_assignment_log = options[:auto_assignment_log].present? ? options[:auto_assignment_log] : nil
    is_auto_assignment = options[:is_auto_assignment].present? ? options[:is_auto_assignment] : false

    # this doesn't appear to be used at all at the moment, leaving because
    # I need to figure out how it was supposed to have been used - jayoung
    submitter_comment = options[:submitter_comment].present? ? options[:submitter_comment] : false

    # is this an assignment to the person already assigned - and not from being
    # reopened by the submitter? do nothing.
    return true if (current_assignee.present? and (assign_to.id ==current_assignee.id) and !submitter_reopen)

    # is this being reassigned?
    if(current_assignee.present? and (assigned_by.id != current_assignee.id))
      is_reassign = true
      previously_assigned_to = current_assignee
    else
      is_reassign = false
    end

    # set the assignee - log it, and notify them
    self.update_attributes(:assignee_id => assign_to.id, :working_on_this => nil, :last_assigned_at => Time.zone.now )

    # update assignment stats for the assignee
    assign_to.update_column(:open_question_count, assign_to.open_questions.count)
    assign_to.update_column(:last_question_assigned_at, Time.zone.now)

    if is_auto_assignment
      QuestionEvent.log_auto_assignment(question: self,
                                        recipient: assign_to,
                                        assignment_comment: comment,
                                        auto_assignment_log: auto_assignment_log)
    else
      QuestionEvent.log_assignment(question: self,
                                   recipient: assign_to,
                                   initiated_by: assigned_by,
                                   assignment_comment: comment)
    end

    # assignment notification
    if !resolving_self_assignment
      if(self.assignee_id != self.current_resolver_id )
        Notification.create(notifiable: self,
                            created_by: User.system_user_id,
                            recipient_id: self.assignee_id,
                            notification_type: Notification::AAE_ASSIGNMENT,
                            delivery_time: 1.minute.from_now )
      end
    end

    # if this is not being assigned to someone who already has it AND it's not a public reopen (the submitter responded)
    if(is_reassign and !submitter_reopen)
      Notification.create(notifiable: self,
                          created_by: User.system_user_id,
                          recipient_id: previously_assigned_to.id,
                          notification_type: Notification::AAE_REASSIGNMENT,
                          delivery_time: 1.minute.from_now )
    end

  end

  # Assigns the question to the group, logs the assignment, and sends an email
  # to the group members signed up for notifications notifying them that a question has been assigned to their group
  def assign_to_group(group, assigned_by, comment)
    if(!group and !group.instance_of?(Group))
      raise AssignmentError, 'Invalid group provided to assign_to_group'
    end

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
    self.update_attributes(:assigned_group => group, :assignee => nil, :working_on_this => nil)
    QuestionEvent.log_group_assignment(self,group,assigned_by,comment)
    if(current_assigned_group != group)
      QuestionEvent.log_group_change(question: self, old_group: current_assigned_group, new_group: group, initiated_by: assigned_by)
    end

    # after reassigning to another group manually, updating the group, logging the group assignment, and logging the group change,
    # if the individual assignment flag is set to true for this group, assign to an individual within this group using the routing algorithm.
    Notification.create(notifiable: self, created_by: assigned_by.id, recipient_id: 1, notification_type: Notification::AAE_ASSIGNMENT_GROUP, delivery_time: 1.minute.from_now )  unless self.assigned_group.incoming_notification_list.empty?
    if group.individual_assignment?
      self.find_group_assignee_and_assign(previously_assigned_user.present? ? [previously_assigned_user] : nil)
    else
      if(is_reassign)
        Notification.create(notifiable: self, created_by: assigned_by.id, recipient_id: previously_assigned_user.id, notification_type: Notification::AAE_REASSIGNMENT, delivery_time: 1.minute.from_now )
      end
    end
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
          self.update_attributes(:status => Question.convert_to_string(q_status), :status_state =>  q_status, :current_resolver => resolver, :current_response => response, :contributing_question => contributing_question, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"), :working_on_this => nil)
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
          self.update_attributes(:status => Question.convert_to_string(q_status), :status_state =>  q_status, :current_resolver => resolver, :current_response => response, :contributing_question => contributing_question, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"), :working_on_this => nil)
          @response.save
          QuestionEvent.log_no_answer(self)
        else
          raise "There is an error in your response: #{@response.errors.full_messages.to_sentence}"
        end
      when STATUS_REJECTED
        self.update_attributes(:status => Question.convert_to_string(q_status), :status_state => q_status, :current_response => response, :current_resolver => resolver, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"), :is_private => true, :is_private_reason => PRIVACY_REASON_REJECTED, :working_on_this => nil)
        QuestionEvent.log_rejection(self)
    end
  end

  def resolved?
    self.status_state != STATUS_SUBMITTED
  end

  def assigned_to_group_queue?
    self.assignee_id.nil? and self.assigned_group_id.present? ? true : false
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

  # get the event of the last response given for a question
  def last_response
    question_event = self.question_events.find(:first, :conditions => "event_state = #{QuestionEvent::RESOLVED} OR event_state = #{QuestionEvent::NO_ANSWER}", :order => "created_at DESC")
    return question_event if question_event
    return nil
  end

  def validate_attachments
    allowable_types = ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png']
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
    # a few questions have gotten through validation with no email address submitted, and caused an app error here. this shouldn't happen under normal circumstances.
    # make sure we catch it.
    begin
      self.question_fingerprint = Digest::MD5.hexdigest(create_time + self.body.to_s + self.email)
    rescue
      errors.add(:base, 'An error occurred while saving your question. Make sure an email address has been submitted and try again.')
      return false
    end
  end

  def set_last_opened
    self.last_opened_at = Time.now
    true
  end

  def set_is_extension
    self.submitter_is_extension = self.submitter.has_exid?
    true
  end

  def notify_submitter
    if(!self.spam? and !self.rejected?)
      Notification.create(notifiable: self, created_by: 1, recipient_id: self.submitter.id, notification_type: Notification::AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT, delivery_time: 1.minute.from_now ) unless self.submitter.nil? or self.submitter.id.nil?
    end
  end


  def is_answered?
    self.status_state == STATUS_RESOLVED
  end

  def needs_response?
    self.status_state != STATUS_RESOLVED &&
    self.status_state != STATUS_NO_ANSWER &&
    self.status_state != STATUS_CLOSED &&
    self.status_state != STATUS_REJECTED
  end

  def create_evaluation_notification
    if(self.is_answered? and !self.submitter.answered_evaluation_for_question?(self) and self.assigned_group.send_evaluation)
      Notification.create(notifiable: self, created_by: self.submitter.id, recipient_id: self.submitter.id, notification_type: Notification::AAE_PUBLIC_EVALUATION_REQUEST, delivery_time: 1.minute.from_now )
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
    list = Preference.where(name: Preference::NOTIFICATION_ACTIVITY, question_id: self.id )
  end

  def rejected?
    return self.status_state == STATUS_REJECTED
  end

  #### data related
    def to_ua_report
    returndata = []
    ua = UserAgent.parse(self.user_agent)
    returndata << self.id
    returndata << self.created_at.to_date.to_s
    returndata << self.created_at.to_i
    if(!self.user_agent.blank?)
      returndata << ua.browser
      returndata << ua.version
      returndata << ua.platform
      returndata << ua.mobile?
    else
      returndata << 'unknown'
      returndata << 'unknown'
      returndata << 'unknown'
      returndata << 'unknown'
    end
    if(!self.location.blank?)
      returndata << self.location.name
    else
      returndata << 'unknown'
    end
    returndata
  end

  def detected_location
    Location.find_by_geoip(self.user_ip)
  end

  def detected_county
    County.find_by_geoip(self.user_ip)
  end

  def is_mobile?
    if(!self.user_agent.blank?)
      ua = UserAgent.parse(self.user_agent)
      ua.mobile?
    else
      nil
    end
  end

  def demographic_eligible?
    (self.created_at >= Time.parse(DEMOGRAPHIC_ELIGIBLE) && self.evaluation_sent?)
  end

  def evaluation_eligible?
    (self.created_at >= Time.parse(EVALUATION_ELIGIBLE) && self.evaluation_sent?)
  end


  def response_times
    self.responses.expert_after_public.pluck(:time_since_last)
  end

  def mean_response_time
    self.response_times.mean || 0
  end

  def median_response_time
    self.response_times.median || 0
  end

  def aae_version
    (self.created_at >= Time.parse(AAE_V2_TRANSITION)) ? 2 : 1
  end

  def source
    if(self.aae_version == 1)
      (self.external_app_id == 'widget') ? 'widget' : 'website'
    else
      (self.referrer =~ %r{widget}) ? 'widget' : 'website'
    end
  end


  def self.ua_report(filename)
    CSV.open(filename, "wb") do |csv|
      csv << ['question_id','date','unixtime','browser','version','platform','mobile?','location']
      with_scope do
        all.each do |question|
          if(!question.user_agent.blank?)
            csv << question.to_ua_report
          end
        end
      end
    end
  end


  def self.evaluation_data_csv(filename)
    CSV.open(filename,'wb') do |csv|
      headers = []
      headers << 'question_id'
      headers << 'question_submitted_at'
      headers << 'submitter_is_extension'
      headers << 'evaluation_count'
      eval_columns = []
      EvaluationQuestion.order(:id).active.each do |aeq|
        eval_columns << "evaluation_#{aeq.id}_response"
        eval_columns << "evaluation_#{aeq.id}_value"
      end
      headers += eval_columns
      csv << headers

      # data
      # evaluation_answer_questions
      eligible_questions = self.evaluation_eligible.pluck(:id)
      response_questions = EvaluationAnswer.pluck(:question_id).uniq
      eligible_response_questions = eligible_questions & response_questions
      self.where("id in (#{eligible_response_questions.join(',')})").includes(:submitter).each do |question|
        eval_count = question.evaluation_answers.count
        next if (eval_count == 0)
        row = []
        row << question.id
        row << question.created_at.strftime("%Y-%m-%d %H:%M:%S")
        row << question.submitter.has_exid?
        row << eval_count
        question_data = {}
        question.evaluation_answers.each do |ea|
          question_data["evaluation_#{ea.evaluation_question_id}_response"] = ea.response
          question_data["evaluation_#{ea.evaluation_question_id}_value"] = ea.evaluation_question.reporting_response_value(ea.response)
        end

        eval_columns.each do |column|
          value = question_data[column]
          if(value.is_a?(Time))
            row << value.strftime("%Y-%m-%d %H:%M:%S")
          else
            row << value
          end
        end

        csv << row
      end
    end
  end


  def self.increase_group_concat_length
    set_group_concat_size_query = "SET SESSION group_concat_max_len = #{Settings.group_concat_max_len};"
    self.connection.execute(set_group_concat_size_query)
  end

  def self.earliest_resolved_at
    with_scope do
      era = self.minimum(:initial_response_at)
      (era < EpochDate::WWW_LAUNCH) ? EpochDate::WWW_LAUNCH : era
    end
  end

  def self.latest_resolved_at
    with_scope do
      self.maximum(:initial_response_at)
    end
  end


  def self.answered_stats_by_yearweek(metric,cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{metric: metric, scope_sql: current_scope ? current_scope.to_sql : ''})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _answered_stats_by_yearweek(metric,cache_options)
        end
      end
    else
      with_scope do
        _answered_stats_by_yearweek(metric,cache_options)
      end
    end
  end

  def self._answered_stats_by_yearweek(metric,cache_options = {})
    stats = YearWeekStats.new
    # increase_group_concat_length
    with_scope do
      era = self.answered.earliest_resolved_at
      if(era.blank?)
        return stats
      end
      lra = self.answered.latest_resolved_at - 1.week

      case metric
      when 'questions'
        metric_by_yearweek = self.answered.group(YEARWEEK_ANSWERED).count(:id)
      when 'responsetime'
        questions_by_yearweek = self.answered.group(YEARWEEK_ANSWERED).count(:id)
        responsetime_by_yearweek = self.answered.group(YEARWEEK_ANSWERED).sum(:initial_response_time)
        metric_by_yearweek = {}
        responsetime_by_yearweek.each do |yearweek,total_response_time|
          metric_by_yearweek[yearweek] = ((questions_by_yearweek[yearweek].nil? or questions_by_yearweek[yearweek] == 0) ? 0 : total_response_time / 3600 / questions_by_yearweek[yearweek].to_f )
        end
      else
        return stats
      end

      year_weeks = self.year_weeks_between_dates(era.to_date,lra.to_date)
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


  def self.latest_yearweek
    (year,week) = latest_year_week
    yearweek(year,week)
  end

  def self.latest_year_week(cache_options = {})
    # cachekey = self.get_cache_key(__method__)
    # Rails.cache.fetch(cachekey,cache_options) do
      if(yearweek = self._latest_year_week)
        latest_year = yearweek[0]
        latest_week = yearweek[1]
      else
        (latest_year,latest_week) = self.last_year_week
      end
      [latest_year,latest_week]
    # end
  end

  def self.latest_date
    (year,week) = self.latest_year_week
    (blah,last_date) = self.date_pair_for_year_week(year,week)
    last_date
  end

  def self._latest_year_week
    year = self.maximum('YEAR(created_at)')
    if(year.nil?)
      nil
    else
      week = self.where(" YEAR(created_at) = ?",year).maximum("WEEKOFYEAR(created_at)")
      if(week.nil?)
        nil
      else
        [year,week]
      end
    end
  end

  def update_data_cache
    QuestionDataCache.create_or_update_from_question(self)
    true
  end

  def data_cache
    if(!(qdc = self.question_data_cache))
      qdc = QuestionDataCache.create_or_update_from_question(self)
    elsif(qdc.version != QuestionDataCache::CURRENT_VERSION)
      qdc = QuestionDataCache.create_or_update_from_question(self)
    end
    qdc.data_values
  end

  def cached_tags(forceupdate = false)
    if(self.cached_tag_hash.nil? or forceupdate)
      update_hash = Hash[self.tags.map{|t| [t.id,t.name]}]
      self.update_column(:cached_tag_hash,update_hash.to_yaml)
      update_hash
    else
      self.cached_tag_hash
    end
  end




  def self.filtered_by(question_filter)
    with_scope do
      base_scope = select('DISTINCT questions.id, questions.*')
      if(question_filter && settings = question_filter.settings)
        QuestionFilter::KNOWN_KEYS.each do |filter_key|
          if(settings[filter_key])
            case filter_key
            when 'question_locations'
              base_scope = base_scope.where("questions.location_id IN (#{settings[filter_key].join(',')})")
            when 'question_counties'
              base_scope = base_scope.where("questions.county_id IN (#{settings[filter_key].join(',')})")
            when 'assigned_groups'
              base_scope = base_scope.where("questions.assigned_group_id IN (#{settings[filter_key].join(',')})")
            when 'tags'
              base_scope = base_scope.joins(:tags).where("tags.id IN (#{settings[filter_key].join(',')})")
            end
          end
        end
      end
      base_scope
    end
  end

  def has_blank_body_when_links_removed?
    CGI.unescapeHTML(self.class.remove_links(self.body)).gsub(/\s+/,'').blank?
  end



end
