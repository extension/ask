# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

require 'valid_email'
class User < ActiveRecord::Base
  extend YearMonth
  include TagUtilities
  
  DEFAULT_TIMEZONE = 'America/New_York'
  DEFAULT_NAME = '"No name provided"'
  SYSTEMS_USERS = [1,2,3,4,5,6,7,8]

  has_many :authmaps
  has_many :comments
  has_many :user_locations
  has_many :user_counties
  has_many :preferences, :as => :prefable
  has_one  :filter_preference
  has_many :expertise_locations, :through => :user_locations, :source => :location
  has_many :expertise_counties, :through => :user_counties, :source => :county
  has_many :notification_exceptions
  has_many :group_connections, :dependent => :destroy
  has_many :group_memberships, :through => :group_connections, :source => :group, :conditions => "connection_type IN ('leader', 'member')", :order => "groups.name", :uniq => true
  has_many :ratings
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  has_many :initiated_question_events, :class_name => 'QuestionEvent', :foreign_key => 'initiated_by_id'
  has_many :submitted_question_events, :class_name => 'QuestionEvent', :foreign_key => 'submitter_id'
  has_many :recipient_question_events, :class_name => 'QuestionEvent', :foreign_key => 'recipient_id'
  has_many :answered_questions, :through => :initiated_question_events, :conditions => "question_events.event_state = #{QuestionEvent::RESOLVED}", :source => :question, :order => 'question_events.created_at DESC', :uniq => true
  has_many :rejected_questions, :through => :initiated_question_events, :conditions => "question_events.event_state = #{QuestionEvent::REJECTED}", :source => :question, :order => 'question_events.created_at DESC', :uniq => true
  has_many :open_questions, :class_name => "Question", :foreign_key => "assignee_id", :conditions => "status_state = #{Question::STATUS_SUBMITTED}"
  has_many :submitted_questions, :class_name => "Question", :foreign_key => "submitter_id"
  has_many :current_resolver_questions, :class_name => "Question", :foreign_key => "current_resolver_id"
  has_many :watched_questions, :through => :preferences, :conditions => "(preferences.name = '#{Preference::NOTIFICATION_ACTIVITY}') AND (preferences.value = true)", :source => :question, :order => 'preferences.created_at DESC', :uniq => true
  has_many :question_viewlogs
  has_many :created_groups, :class_name => "Group", :foreign_key => "created_by"
  has_one  :yo_lo
  has_many :demographics
  has_many :evaluation_answers
  has_many :user_events
  has_many :activity_logs
  has_many :created_group_events, :class_name => "GroupEvent", :foreign_key => "created_by"
  has_many :recipient_group_events, :class_name => "GroupEvent", :foreign_key => "recipient_id"
  has_many :mailer_caches, :class_name => "MailerCache", :foreign_key => "user_id"
  has_many :created_notifications, :class_name => "Notification", :foreign_key => "created_by"
  has_many :recipient_notifications, :class_name => "Notification", :foreign_key => "recipient_id"
  has_many :previous_recipient_question_events, :class_name => "QuestionEvent", :foreign_key => "previous_recipient_id"
  has_many :previous_initiator_question_events, :class_name => "QuestionEvent", :foreign_key => "previous_initiator_id"
  has_many :previous_handling_recipient_question_events, :class_name => "QuestionEvent", :foreign_key => "previous_handling_recipient_id"
  has_many :previous_handling_initiator_question_events, :class_name => "QuestionEvent", :foreign_key => "previous_handling_initiator_id"
  has_many :submitted_responses, :class_name => "Response", :foreign_key => "submitter_id"
  has_many :resolved_responses, :class_name => "Response", :foreign_key => "resolver_id"
  
  
  belongs_to :location
  belongs_to :county

  # sunspot/solr search
  searchable :if => proc { |user| (user.has_exid? == true) && (user.id.present? && user.id > 8) } do
    text :name
    text :bio
    text :login
    text :email
    text :tag_fulltext
    boolean :retired
    boolean :is_blocked
    string :kind
    time :last_active_at
  end


  devise :rememberable, :trackable, :database_authenticatable

  has_attached_file :avatar, :styles => { :medium => "100x100#", :thumb => "40x40#", :mini => "20x20#" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"

  validates_attachment :avatar, :size => { :less_than => 8.megabytes },
    :content_type => { :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png'] }

  # validation should not happen when someone initially signs in with a twitter account and does not have an email address initially b/c twitter 
  # does not pass email information back.
  validates :email, :presence => true, :email => true, unless: Proc.new { |u| u.first_authmap_twitter? }
  
  before_update :update_vacated_aae
  before_save :update_aae_status_for_public

  scope :tagged_with, lambda {|tag_id|
    {:include => {:taggings => :tag}, :conditions => "tags.id = '#{tag_id}' AND taggings.taggable_type = 'User'"}
  }

  scope :with_expertise_county, lambda {|county_id| joins(:expertise_counties).where("user_counties.county_id = #{county_id}") }
  scope :with_expertise_location, lambda {|location_id| joins(:expertise_locations).where("user_locations.location_id = #{location_id}") }
  scope :with_expertise_location_all_counties, lambda {|location_id| joins(:expertise_counties).where("counties.location_id = #{location_id} AND counties.name = 'All'")}
  scope :question_wranglers, conditions: { is_question_wrangler: true }
  scope :active, conditions: { away: false, retired: false }
  scope :route_from_anywhere, conditions: { routing_instructions: 'anywhere' }
  scope :exid_holder, conditions: "kind = 'User' AND users.id NOT IN (#{SYSTEMS_USERS.join(',')})"
  scope :not_retired, conditions: { retired: false }
  scope :not_blocked, conditions: { is_blocked: false }
  scope :not_system, conditions: "id NOT IN (#{SYSTEMS_USERS.join(',')})"
  scope :valid_users, not_retired.merge(not_blocked).merge(not_system)
  scope :daily_summary_notification_list, joins(:preferences).where("preferences.name = '#{Preference::NOTIFICATION_DAILY_SUMMARY}'").where("preferences.value = #{true}").group('users.id')
  # special scope for returning an empty AR association
  scope :none, where('1 = 0')
  
  scope :tagged_with_any, lambda { |tag_array|
    tag_list = tag_array.map{|t| "'#{t.name}'"}.join(',') 
    joins(:tags).select("#{self.table_name}.*, COUNT(#{self.table_name}.id) AS tag_count").where("tags.name IN (#{tag_list})").group("#{self.table_name}.id").order("tag_count DESC") 
  }
  
  scope :group_membership_for, lambda { |group_id| joins(:group_connections => :group).where("group_connections.group_id = #{group_id}")}
  scope :from_location, lambda{ |location| joins(:location).where("locations.id = #{location.id}")}
  scope :from_county, lambda{ |county| joins(:county).where("counties.id = #{county.id}")}
  scope :needs_search_update, lambda{ where(needs_search_update: true)}

  scope :pattern_search, lambda {|searchterm, type = nil|
    # remove any leading * to avoid borking mysql
    # remove any '\' characters because it's WAAAAY too close to the return key
    # strip '+' and '?' characters because it's causing a repetition search error
    # strip parens '()' to keep it from messing up mysql query
    # strip brackets
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\?/,'').strip

    if sanitizedsearchterm == ''
      return {:conditions => 'false'}
    end

    # in the format wordone wordtwo?
    words = sanitizedsearchterm.split(%r{\s*,\s*|\s+})
    if(words.length > 1 && !words[0].blank? && !words[1].blank?)
      if type.nil?
        findvalues = {
         :firstword => words[0],
         :secondword => words[1]
        }
      elsif type == "prefix"
        findvalues = {
         :firstword => "^#{words[0]}",
         :secondword => "^#{words[1]}"
        }
      end
      
      conditions = ["((first_name rlike :firstword AND last_name rlike :secondword) OR (first_name rlike :secondword AND last_name rlike :firstword))",findvalues]
    else
      if type.nil?
        conditions = ["(first_name rlike ? OR last_name rlike ? OR login rlike ?)", sanitizedsearchterm, sanitizedsearchterm, sanitizedsearchterm]
      elsif type == "prefix"
        conditions = ["(first_name rlike ? OR last_name rlike ? OR login rlike ?)", "^#{sanitizedsearchterm}", "^#{sanitizedsearchterm}", "^#{sanitizedsearchterm}"]
      end
    end
    {:conditions => conditions}
  }
  
  # the first authmap is twitter if either it's a new record and we're saving the first authmap to it or 
  # more than one authmap exists for the user and the first one is the twitter authmap
  def first_authmap_twitter?
    twitter_authmap = self.authmaps.detect{|am| am.source == 'twitter'}
    twitter_authmap.present? && (self.authmaps.length == 1 || (self.authmaps.order(:created_at).first.id == twitter_authmap.id))
  end
  
  
  def self.by_question_event_count(event_state,options = {})
    with_scope do
      (options[:yearmonth].present? && options[:yearmonth] =~ /-/) ? date_string = '%Y-%m' : date_string = '%Y'
        
      qe_scope = self.exid_holder.not_retired
      .select("users.*, 
               COUNT(DISTINCT IF(question_events.event_state = #{event_state}, question_id, NULL)) AS resolved_count")
      .joins("LEFT JOIN question_events on question_events.initiated_by_id = users.id")
      .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",options[:yearmonth]).group("initiated_by_id")
        
      qe_scope = qe_scope.limit(options[:limit]) if options[:limit].present?
      qe_scope.order("resolved_count DESC")
    end
  end

  def name
    if (self.first_name.present? && self.last_name.present?)
      return self.first_name + " " + self.last_name
    elsif self.public_name.present?
      return self.public_name
    end
    return DEFAULT_NAME
  end

  def public_name
    if self[:public_name].present?
      return self[:public_name]
    elsif (self[:first_name].present? && self[:last_name].present?)
      return self[:first_name].capitalize + " " + self[:last_name][0,1].capitalize + "."
    end
    return DEFAULT_NAME
  end
  
  def self.to_csv(users, fields, options = {})
    fields = self.column_names if fields.blank?
    CSV.generate(options) do |csv| 
      csv << fields
      users.each do |user|
        csv << user.attributes.values_at(*fields)
      end
    end
  end

  def tag_fulltext
    self.tags.map(&:name).join(' ')
  end

  def member_of_group(group)
    find_group = self.group_connections.where('group_id = ?', group.id)
    !find_group.blank?
  end

  def leader_of_group(group)
    find_group = self.group_connections.where('group_id = ?', group.id).where('connection_type = ?', 'leader')
    !find_group.blank?
  end

  def self.system_user_id
    return 1
  end

  def self.system_user
   find(1)
  end

  def has_exid?
    return self.kind == 'User'
  end

  def retired?
    return self.retired
  end
    
  def previously_assigned(question)
    find_question = QuestionEvent.where('question_id = ?', question.id).where("event_state = #{QuestionEvent::ASSIGNED_TO}").where("recipient_id = ?",self.id)
    !find_question.blank?
  end

  def update_vacated_aae
    if self.away_changed?
      if self.away == true
        self.vacated_aae_at = Time.now
      else
        self.vacated_aae_at = nil
      end
    end
  end
  
  def get_pref(pref_name)
    return self.preferences.find(:first, conditions: {name: pref_name})
  end
  
  def log_create_group(group)
    GroupEvent.log_group_creation(group, self, self)
  end
  
  def join_group(group, connection_type)
    if (connection = GroupConnection.where(user_id: self.id, group_id: group.id).first)
      connection.destroy
    end

    group_connection = self.group_connections.create(group: group, connection_type: connection_type)
    return if !group_connection.valid?

    if connection_type == 'leader'
      GroupEvent.log_added_as_leader(group, self, self)
      Preference.create_or_update(self, Preference::NOTIFICATION_DAILY_SUMMARY, true, group.id) #leaders are opted into daily summaries / escalations
    else
      GroupEvent.log_group_join(group, self, self)
    end

    # question wrangler group?
    if(group.id == Group::QUESTION_WRANGLER_GROUP_ID)
      if(connection_type == 'leader' || connection_type == 'member')
        self.update_attribute(:is_question_wrangler, true)
        Preference.create_or_update(self, Preference::NOTIFICATION_INCOMING, true, group.id) 
      end
    end

  end

  # instance method version of aae_handling_event_count
  def aae_handling_event_count(options = {})
    myoptions = options.merge({:group_by_id => true, :limit_to_handler_ids => [self.id]})
    result = self.class.aae_handling_event_count(myoptions)
    if(result.present? && result[self.id].present?)
      returnvalues = result[self.id]
    else
      returnvalues = {:total => 0, :handled => 0, :ratio => 0}
    end
    return returnvalues
  end

  def self.aae_handling_event_count(options = {})
    # narrow by recipients
    !options[:limit_to_handler_ids].blank? ? recipient_condition = "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})" : recipient_condition = nil
    # default date interval is 6 months
    date_condition = "created_at > date_sub(curdate(), INTERVAL 6 MONTH)"
    # group by user id's or user objects?
    group_clause = (options[:group_by_id] ? 'previous_handling_recipient_id' : 'previous_handling_recipient')

    # get the total number of handling events
    conditions = []
    conditions << date_condition
    conditions << recipient_condition if recipient_condition.present?
    totals_hash = QuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)

    # pull all question events for where someone pulled the question from them within 24 hours and do not count those
    conditions = ["initiated_by_id <> previous_handling_recipient_id"]
    conditions << date_condition
    conditions << "duration_since_last_handling_event <= 86400"
    conditions << recipient_condition if recipient_condition.present?
    negated_hash = QuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)

    # get the total number of handling events for which I am the previous recipient *and* I was the initiator.
    conditions = ["initiated_by_id = previous_handling_recipient_id"]
    conditions << date_condition
    conditions << recipient_condition if recipient_condition.present?
    handled_hash = QuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)

    # loop through the total list, build a return hash
    # that will return the values per user_id (or user object)
    returnvalues = {}
    returnvalues[:all] = {:total => 0, :handled => 0, :ratio => 0}
    totals_hash.keys.each do |groupkey|
      total = totals_hash[groupkey]
      total = total - negated_hash[groupkey].to_i if !negated_hash[groupkey].nil?
      handled = (handled_hash[groupkey].nil?? 0 : handled_hash[groupkey])
      # calculate a floating point ratio
      if(handled > 0)
        ratio = handled.to_f / total.to_f
      else
        ratio = 0
      end
      returnvalues[groupkey] = {:total => total, :handled => handled, :ratio => ratio}
      returnvalues[:all][:total] += total
      returnvalues[:all][:handled] += handled
    end
    if(returnvalues[:all][:handled] > 0)
      returnvalues[:all][:ratio] = returnvalues[:all][:handled].to_f / returnvalues[:all][:total].to_f
    end

    return returnvalues
  end

  def leave_group(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('connection_type = ?', connection_type).where('group_id = ?',group.id).first)
      connection.destroy
      GroupEvent.log_group_leave(group, self, self)
    end

    # question wrangler group?
    if(group.id == Group::QUESTION_WRANGLER_GROUP_ID)
      self.update_attribute(:is_question_wrangler, false)
    end
  end

  def update_aae_status_for_public
    if self.kind == 'PublicUser'
      self.away = true
    end
  end

  def leave_group_leadership(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('connection_type = ?', connection_type).where('group_id = ?',group.id).first)
      connection.destroy
      self.group_connections.create(group: group, connection_type: "member")
      GroupEvent.log_removed_as_leader(group, self, self)
    end
  end

  def send_assignment_notification?(group)
    self.preferences.setting(Preference::NOTIFICATION_ASSIGNED_TO_ME,group)
  end

  def send_incoming_notification?(group)
    self.preferences.setting(Preference::NOTIFICATION_INCOMING, group)
  end
  
  def send_activity_notification?(question)
    self.preferences.setting(Preference::NOTIFICATION_ACTIVITY, nil, question)
  end

  def send_daily_summary?(group)
    self.preferences.setting(Preference::NOTIFICATION_DAILY_SUMMARY, group)
  end

  # override timezone writer/reader
  # returns Eastern by default, use convert=false
  # when you need a timezone string that mysql can handle
  def time_zone(convert=true)
    tzinfo_time_zone_string = read_attribute(:time_zone)
    if(tzinfo_time_zone_string.blank?)
      tzinfo_time_zone_string = DEFAULT_TIMEZONE
    end

    if(convert)
      reverse_mappings = ActiveSupport::TimeZone::MAPPING.invert
      if(reverse_mappings[tzinfo_time_zone_string])
        reverse_mappings[tzinfo_time_zone_string]
      else
        nil
      end
    else
      tzinfo_time_zone_string
    end
  end

  def time_zone=(time_zone_string)
    mappings = ActiveSupport::TimeZone::MAPPING
    if(mappings[time_zone_string])
      write_attribute(:time_zone, mappings[time_zone_string])
    else
      write_attribute(:time_zone, nil)
    end
  end

  # since we return a default string from timezone, this routine
  # will allow us to check for a null/empty value so we can
  # prompt people to come set one.
  def has_time_zone?
    tzinfo_time_zone_string = read_attribute(:time_zone)
    return (!tzinfo_time_zone_string.blank?)
  end

  # this is mostly for the mailer situation where
  # we aren't setting Time.zone for the web request
  def time_for_user(datetime)
    logger.debug "In time_for_user #{self.id}"
    self.has_time_zone? ? datetime.in_time_zone(self.time_zone) : datetime.in_time_zone(Settings.default_display_timezone)
  end
  
  def last_view_for_question(question)
    activity = self.question_viewlogs.views.where(question_id: question.id).first
    if(!activity.blank?)
      activity.activity_logs.order('created_at DESC').pluck(:created_at).first
    else
      nil
    end
  end
  
  def daily_summary_group_list
    list = []
    self.group_memberships.each{|group| list.push(group) if (send_daily_summary?(group) and group.include_in_daily_summary?)}
    return list
  end

  def completed_demographics?
    active_demographic_questions = DemographicQuestion.active.pluck(:id)
    my_demographic_questions = self.demographics.pluck(:demographic_question_id)
    (active_demographic_questions - my_demographic_questions).blank?
  end

  def answered_evaluation_for_question?(question)
    active_evaluation_questions = EvaluationQuestion.active.pluck(:id)
    my_evaluation_questions_for_this_question = self.evaluation_answers.where(question_id: question.id).pluck(:evaluation_question_id)
    ((active_evaluation_questions & my_evaluation_questions_for_this_question).size > 0)
  end

  # reporting

  def earliest_assigned_at
    QuestionEvent.where("event_state = #{QuestionEvent::ASSIGNED_TO}").where("recipient_id = ?",self.id).minimum(:created_at)
  end

  def assigned_count_by_year
    QuestionEvent.where("event_state = #{QuestionEvent::ASSIGNED_TO}").where("recipient_id = ?",self.id).group("YEAR(created_at)").count('DISTINCT(question_id)')
  end

  def assigned_count_by_year_month
    QuestionEvent.where("event_state = #{QuestionEvent::ASSIGNED_TO}").where("recipient_id = ?",self.id).group("DATE_FORMAT(created_at,'%Y-%m')").count('DISTINCT(question_id)')
  end

  def assigned_list_for_year_month(year_month)
    year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
    Question.select("DISTINCT(questions.id), questions.*")
    .joins(:question_events)
    .where("question_events.event_state = #{QuestionEvent::ASSIGNED_TO}")
    .where("question_events.recipient_id = ?",self.id)
    .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month)
  end

  def answered_count_by_year
    QuestionEvent.where("event_state = #{QuestionEvent::RESOLVED}").where("initiated_by_id = ?",self.id).group("YEAR(created_at)").count('DISTINCT(question_id)')
  end

  def answered_count_by_year_month
    QuestionEvent.where("event_state = #{QuestionEvent::RESOLVED}").where("initiated_by_id = ?",self.id).group("DATE_FORMAT(created_at,'%Y-%m')").count('DISTINCT(question_id)')
  end

  def answered_list_for_year_month(year_month)
    year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
    Question.select("DISTINCT(questions.id), questions.*")
    .joins(:question_events)
    .where("question_events.event_state = #{QuestionEvent::RESOLVED}")
    .where("question_events.initiated_by_id = ?",self.id)
    .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month)
  end
  
  def touched_count_by_year
    QuestionEvent.where("initiated_by_id = ?",self.id).group("YEAR(created_at)").count('DISTINCT(question_id)')
  end

  def touched_count_by_year_month
    QuestionEvent.where("initiated_by_id = ?",self.id).group("DATE_FORMAT(created_at,'%Y-%m')").count('DISTINCT(question_id)')
  end
  
  def touched_list_for_year_month(year_month)
    year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
    Question.select("DISTINCT(questions.id), questions.*")
    .joins(:question_events)
    .where("question_events.initiated_by_id = ?",self.id)
    .where("DATE_FORMAT(question_events.created_at,'#{date_string}') = ?",year_month)
  end
  
  # this instance method used to merge two user accounts into one account, particularly used 
  # when merging two accounts created for the same user resulting from a user using 
  # more than one method of authentication (eg. twitter, eXtension, etc.)
  def merge_account_with(user_id)
    user_to_merge_with = User.find_by_id(user_id)
    # we're keeping the first user account created and merging the later one with it 
    # along with destroying the later account when the merging is complete
    if user_to_merge_with.created_at > self.created_at 
      user_to_keep = self
      user_to_remove = user_to_merge_with
    else
      user_to_keep = user_to_merge_with
      user_to_remove = self
    end
    
    User.reflect_on_all_associations.each do |association_to_user|
      # make sure we have the field we need to use for the user for the associated tables
      if !association_to_user.options[:foreign_key].blank?
        key_of_user = association_to_user.options[:foreign_key]
      else
        key_of_user = nil
      end
      
      additional_conditions = ''
      
      case association_to_user.macro 
      when :has_many || :has_one
        # in the case of :has_one, I think it's pretty rare to see the :through and :as options get used,  
        # but I'm going to cover it along with :has_many anyways
        
        # operate on the 'through' table if it's has_many :through
        if !association_to_user.options[:through].blank?
          model_to_use = association_to_user.options[:through].to_s.singularize.camelize.constantize
          key_of_user = "user_id" if key_of_user.blank?
        # the association name in the associated table will be different if we have options[:as] (polymorphic association)
        # and we'll need to update all records with options[:as]_id in the associated table
        elsif !association_to_user.options[:as].blank?
          # get the class name of the associated table and the user key (eg. prefable_id)
          key_of_user = "#{association_to_user.options[:as]}_id"
          model_to_use = association_to_user.klass
          # need to get the type on a polymorphic association (eg. prefable_type)
          additional_conditions = " AND #{association_to_user.options[:as]}_type = 'User'"
        else
          # the code below also works for the :class_name option b/c klass is pulling the target model
          key_of_user = "user_id" if key_of_user.blank?
          model_to_use = association_to_user.klass
        end
        
        model_to_use.where("#{key_of_user} = #{user_to_remove.id}" + "#{additional_conditions}").update_all(key_of_user.to_sym => user_to_keep.id)
      when :has_and_belongs_to_many
        join_table = association_to_user.options[:join_table]
        if !association_to_user.options[:foreign_key].blank?
          key_of_user = association_to_user.options[:foreign_key]
        else
          key_of_user = 'user'
        end
        # do raw sql here to update a join table without having to instantiate the objects and do AR (delete old and add new) operations 
        # that triggers callbacks.
        connection.execute("UPDATE #{join_table} SET #{key_of_user} = #{user_to_keep.id} WHERE #{key_of_user} = #{user_to_remove.id}")
      end
    end
    
    # if the user record from eXtension authentication is the user record to be removed, 
    # then transfer the darmok_id to the remaining user account b/c that's needed for sync with people.
    if !user_to_remove.darmok_id.blank?
      User.where("id = #{user_to_keep.id}").update_all(:darmok_id => user_to_remove.darmok_id)
    end
    
    user_to_remove.destroy
  end


end
