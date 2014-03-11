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

  ## includes
  include MarkupScrubber
  include Rakismet::Model
  include CacheTools
  include TagUtilities
  extend NilUtils

  ## attributes
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
  This question has been assigned to you because a new comment has been
  posted to an expert's response or open question who has marked aae
  vacation status. Please reply using the link below or close the
  question out if no reply is needed. Thank You.
  END_TEXT

  DECLINE_ANSWER = <<-END_TEXT.gsub(/\s+/, " ").strip
  Thank you for your question for eXtension. The topic area in which
  you've made a request is not yet fully staffed by eXtension experts
  and therefore we cannot provide you with a timely answer. Instead,
  if you live in the United States, please consider contacting the
  Cooperative Extension office closest to you. Simply go to
  http://www.extension.org, drop in your zip code and choose the
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
  has_many :comments
  has_many :ratings
  has_many :responses
  accepts_nested_attributes_for :responses
  has_many :question_events
  has_many :question_viewlogs, dependent: :destroy
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings


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
  scope :answered, where(:status_state => STATUS_RESOLVED)
  scope :submitted, where(:status_state => STATUS_SUBMITTED)
  scope :not_rejected, conditions: "status_state <> #{STATUS_REJECTED}"
  # special scope for returning an empty AR association
  scope :none, where('1 = 0')

  scope :evaluation_eligible, where("created_at >= ?",Time.parse(EVALUATION_ELIGIBLE)).where(evaluation_sent: true)
  scope :demographic_eligible, where("created_at >= ?",Time.parse(DEMOGRAPHIC_ELIGIBLE)).where(evaluation_sent: true)


  ## validations
  validates :body, :presence => true
  validate :validate_attachments

  ## filters
  before_create :generate_fingerprint, :set_last_opened
  after_create :check_spam, :auto_assign_by_preference, :notify_submitter, :send_global_widget_notifications, :index_me
  after_update :index_me

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


  ## instance methods

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


  def auto_assign(assignees_to_exclude = nil)
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

      if assignees_to_exclude.present?
        group_assignees = group.assignees.where("users.id NOT IN (#{assignees_to_exclude.map{|assignee| assignee.id}.join(',')})")
      else
        group_assignees = group.assignees
      end

      if group_assignees.length > 0
        if (group.ignore_county_routing == true) && self.location.present?
          assignee = pick_user_from_list(group_assignees.with_expertise_location(self.location.id))
        else
          if self.county.present?
            assignee = pick_user_from_list(group_assignees.with_expertise_county(self.county.id))
          end
          if !assignee && self.location.present?
            assignee = pick_user_from_list(group_assignees.with_expertise_location_all_counties(self.location.id))
          end
        end

        if !assignee
          assignee = pick_user_from_list(group_assignees.active.route_from_anywhere)
        end
        # still aint got no one? assign to a group leader
        if !assignee
          if assignees_to_exclude.present?
            group_leaders = group.leaders.active.where("users.id NOT IN (#{assignees_to_exclude.map{|assignee| assignee.id}.join(',')})")
          else
            group_leaders = group.leaders.active
          end

          if group_leaders.length > 0
            assignee = pick_user_from_list(group_leaders)
          # still aint got no one? really?? Wrangle that bad boy.
          else
            assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county, assignees_to_exclude))
          end
        end
      # if individual assignment is turned on for the group and there are no active assignees, wrangle it
      else
        assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county, assignees_to_exclude))
      end
    else
      # send to the question wrangler group if the location of the question is not in the location of the group and
      # the group is not receiving questions from outside their defined locations.
      assignee = pick_user_from_list(Group.get_wrangler_assignees(self.location, self.county, assignees_to_exclude))
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
  def assign_to(user, assigned_by, comment, public_reopen = false, public_comment = nil, resolving_assign = false)
    raise ArgumentError unless user and user.instance_of?(User)

    # don't bother doing anything if this is assignment to the person already assigned unless it's
    # a question that's been responded to by the public after it's been resolved that then gets
    # assigned to whomever the question was last assigned to (unless that person is on vacation)
    return true if self.assignee && user.id == assignee.id && public_reopen == false

    if(self.assignee.present? && (assigned_by != self.assignee))
      is_reassign = true
      previously_assigned_to = self.assignee
    else
      is_reassign = false
    end

    # update and log
    self.working_on_this = nil
    self.update_column(:assignee_id, user.id)

    QuestionEvent.log_assignment(self,user,assigned_by,comment)
    # if this is a reopen reassignment due to the public user commenting on the sq
    if public_comment
      asker_comment = public_comment.body
    else
      asker_comment = nil
    end

    # if this is being assigned to an expert who is resolving the question, do not notify that expert, the question will be resolved
    if !resolving_assign
      Notification.create(notifiable: self, created_by: 1, recipient_id: self.assignee_id, notification_type: Notification::AAE_ASSIGNMENT, delivery_time: 1.minute.from_now ) unless self.assignee.nil? or self.assignee == self.current_resolver #individual assignment notification
    end

    # if this is not being assigned to someone who already has it AND it's not a public reopen (the submitter responded)
    if(is_reassign && public_reopen == false)
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
    self.update_attributes(:assigned_group => group, :assignee => nil, :working_on_this => nil)
    QuestionEvent.log_group_assignment(self,group,assigned_by,comment)
    if(current_assigned_group != group)
      QuestionEvent.log_group_change(question: self, old_group: current_assigned_group, new_group: group, initiated_by: assigned_by)
    end

    # after reassigning to another group manually, updating the group, logging the group assignment, and logging the group change,
    # if the individual assignment flag is set to true for this group, assign to an individual within this group using the routing algorithm.
    if group.individual_assignment == true
      auto_assign(previously_assigned_user.present? ? [previously_assigned_user] : nil)
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
    if(!self.spam? and !self.rejected?)
      Notification.create(notifiable: self, created_by: 1, recipient_id: self.submitter.id, notification_type: Notification::AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT, delivery_time: 1.minute.from_now ) unless self.submitter.nil? or self.submitter.id.nil?
    end
  end

  def send_global_widget_notifications
    if(!self.spam? and !self.rejected?)
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

  def question_comment_notification_list
    return Preference.where(name: Preference::NOTIFICATION_COMMENTS, question_id: self.id, value: true)
  end

  # if the pref for notification_comments does not exist or it has a value of true, then they are opted into comment notifications, otherwise,
  # the pref exists, and the value is set to false indicating they have opted out.
  def opted_into_comment_notifications?(user_id)
    if Preference.where(name: Preference::NOTIFICATION_COMMENTS, question_id: self.id, value: false, prefable_type: 'User', prefable_id: user_id).present?
      return false
    else
      return true
    end
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
    self.response_times.mean
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
      self.not_rejected.each do |question|
        if(!question.user_agent.blank?)
          csv << question.to_ua_report
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
      AaeEvaluationQuestion.order(:id).active.each do |aeq|
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

end
