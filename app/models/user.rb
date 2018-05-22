# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class User < ActiveRecord::Base
  # includes
  extend YearMonth
  include TagUtilities

  # attributes
  # remove extra whitespace from these attributes
  auto_strip_attributes :first_name, :last_name, :email, :squish => true

  # sunspot/solr search
  searchable :if => proc { |user| (user.has_exid? == true) && (user.id.present? && user.id > 8) } do
    text :name, :as => :name_textp
    text :bio
    text :login, :as => :login_textp
    text :email
    text :tag_fulltext
    boolean :unavailable
    string :kind
    time :last_activity_at
  end

  # constants
  DEFAULT_TIMEZONE = 'America/New_York'
  DEFAULT_NAME = '"Anonymous"'
  SYSTEMS_USERS = [1,2,3,4,5,6,7,8]
  EMAIL_VALIDATION_REGEX = Regexp.new('\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z',Regexp::IGNORECASE)

  # unavailable reasons
  UNAVAILABLE_RETIRED = 1
  UNAVAILABLE_CONFIRM_EMAIL = 2
  UNAVAILABLE_TOU_HALT = 3

  # associations
  has_many :authmaps
  has_many :user_locations
  has_many :user_counties
  has_many :preferences, :as => :prefable
  has_one  :filter_preference
  has_many :expertise_locations, :through => :user_locations, :source => :location
  has_many :expertise_counties, :through => :user_counties, :source => :county
  has_many :notification_exceptions
  has_many :group_connections, :dependent => :destroy
  has_many :groups, through: :group_connections
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  has_many :initiated_question_events, :class_name => 'QuestionEvent', :foreign_key => 'initiated_by_id'
  has_many :submitted_question_events, :class_name => 'QuestionEvent', :foreign_key => 'submitter_id'
  has_many :recipient_question_events, :class_name => 'QuestionEvent', :foreign_key => 'recipient_id'
  has_many :answered_questions, :through => :initiated_question_events, :conditions => "question_events.event_state = #{QuestionEvent::RESOLVED}", :source => :question, :order => 'question_events.created_at DESC', :uniq => true
  has_many :rejected_questions, :through => :initiated_question_events, :conditions => "question_events.event_state = #{QuestionEvent::REJECTED}", :source => :question, :order => 'question_events.created_at DESC', :uniq => true
  has_many :assigned_questions, :class_name => "Question", :foreign_key => "assignee_id"
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
  has_attached_file :avatar, :styles => { :medium => "100x100#", :thumb => "40x40#", :mini => "20x20#" }, :url => "/uploads/:class/:attachment/:id_partition/:basename_:style.:extension"


  # scopes
  scope :tagged_with, lambda {|tag_id|
    {:include => {:taggings => :tag}, :conditions => "tags.id = '#{tag_id}' AND taggings.taggable_type = 'User'"}
  }

  scope :with_expertise_county, lambda {|county_id| joins(:expertise_counties).where("user_counties.county_id = #{county_id}") }
  scope :with_expertise_location, lambda {|location_id| joins(:expertise_locations).where("user_locations.location_id = #{location_id}") }
  scope :with_expertise_location_all_counties, lambda {|location_id| joins(:expertise_counties).where("counties.location_id = #{location_id} AND counties.name = 'All'")}
  scope :question_wranglers, -> {where(is_question_wrangler: true)}
  scope :route_from_anywhere, -> {where(routing_instructions: 'anywhere')}
  scope :route_from_location, -> {where(routing_instructions: ['anywhere','locations_only'])}
  scope :exid_holder, conditions: "kind = 'User' AND users.id NOT IN (#{SYSTEMS_USERS.join(',')})"
  scope :not_unavailable, -> { where(unavailable: false) }
  scope :not_system,  -> { where("users.id NOT IN (#{SYSTEMS_USERS.join(',')})") }
  scope :valid_users, -> { not_unavailable.not_system }
  scope :not_away, -> { where(away:false) }
  scope :auto_route, -> { where(auto_route:true) }
  scope :assignable, -> { exid_holder.valid_users.not_away }

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

  # validations
  validates_attachment :avatar, :size => { :less_than => 8.megabytes },
    :content_type => { :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png'] }

  # does not pass email information back.
  validates :email, :presence => true, :email => true

  # filters
  before_update :update_vacated_aae
  before_save :update_aae_status_for_public

  def is_systems_account?
    SYSTEMS_USERS.include?(self.id)
  end

  def signin_allowed?
    !self.unavailable? and !is_systems_account?
  end

  def self.by_question_event_count(event_state,options = {})
    with_scope do
      (options[:yearmonth].present? && options[:yearmonth] =~ /-/) ? date_string = '%Y-%m' : date_string = '%Y'

      qe_scope = self.exid_holder.not_unavailable
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
    self.group_ids.include?(group.id)
  end

  def tagged_with_tag(tag)
    self.tag_ids.include?(tag.id)
  end

  def group_memberships
    self.groups.order("groups.name")
  end

  def leader_of_group(group)
    (leader_connection = self.group_connections.where(connection_type: 'leader').where(group_id: group.id).first)
    leader_connection.present?
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

  def available?
    if(self.away? or self.unavailable?)
      return false
    end
    return true
  end

  def unavailable_reason_to_s
    case unavailable_reason
    when UNAVAILABLE_RETIRED
      "Retired Account"
    when UNAVAILABLE_CONFIRM_EMAIL
      "Waiting Email confirmation"
    when UNAVAILABLE_TOU_HALT
      "Waiting Terms of Use Acceptance"
    else
      ''
    end
  end

  def previously_assigned(question)
    find_question = QuestionEvent.where('question_id = ?', question.id).where("question_events.event_state IN (#{QuestionEvent::ASSIGNED_TO},#{QuestionEvent::AUTO_ASSIGNED_TO})").where("recipient_id = ?",self.id)
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

  def add_expertise_county(county, added_by = User.system_user)
    county_id_list = self.user_counties.map(&:county_id)
    return if(county_id_list.include?(county.id)) # already connected, peace out
    all_county = county.location.get_all_county

    if(county.id == all_county.id)
      # delete all other county associations, no callbacks
      self.expertise_counties.delete_all
    else
      # delete all county if present
      if(all_county_connection = self.user_counties.where(county_id: all_county.id).first)
        # delete connection
        all_county_connection.delete
      end
    end

    # add the county
    self.user_counties.create(county_id: county.id)
    # add the location (don't care if it fails)
    self.user_locations.create(location_id: county.location.id)

    change_hash = Hash.new
    change_hash[:expertise_locations] = {:old => "", :new => county.name}
    UserEvent.log_added_county(self, added_by, change_hash)
  end


  def get_locations_with_open_questions
    expertise_location_ids = self.expertise_locations.map{|l| l.id}.join(',')
    if expertise_location_ids.present?
      return Location.joins(:questions_with_origin).select("locations.*, COUNT(locations.id) AS open_count").where("locations.id IN (#{expertise_location_ids}) AND questions.status_state = #{Question::STATUS_SUBMITTED}").group("locations.id")
    else
      return []
    end
  end

  def get_counties_with_open_questions
    expertise_county_ids = self.expertise_counties.map{|c| c.id}.join(',')
    if expertise_county_ids.present?
      return County.joins(:questions_with_origin).select("counties.*, COUNT(counties.id) AS open_count").where("counties.id IN (#{expertise_county_ids}) AND questions.status_state = #{Question::STATUS_SUBMITTED}").group("counties.id")
    else
      return []
    end
  end

  def get_tags_with_open_questions
    user_tags = self.tags.used_at_least_once
    if user_tags.present?
      return Tag.tags_with_open_question_frequency(user_tags)
    else
      return []
    end
  end

  def get_pref(pref_name)
    return self.preferences.find(:first, conditions: {name: pref_name})
  end

  def join_group(group, connection_type)
    group.connect_user_to_group(self, connection_type)
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

  def update_aae_status_for_public
    if self.kind == 'PublicUser'
      self.away = true
    end
  end

  def leave_group_leadership(group)
    if(connection = self.group_connections.where(connection_type: 'leader').first)
      group.connect_user_to_group(self, 'member')
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

  def last_question_touched_at(return_default_date = false)
    # if they've never touched a question, we can't return nil when sorting
    # because nil can't be used in a sort - so let's return the created_at
    # for the first question_event ever
    return_default_date ? (read_attribute(:last_question_touched_at) || QuestionEvent::FIRST_CONTACT) : read_attribute(:last_question_touched_at)
  end


  def last_question_assigned_at(return_default_date = false)
    # if they've never been assigned a question, we can't return nil when sorting
    # because nil can't be used in a sort - so let's return the created_at
    # for the first question_event ever
    return_default_date ? (read_attribute(:last_question_assigned_at) || QuestionEvent::FIRST_CONTACT) : read_attribute(:last_question_assigned_at)
  end

  def open_questions
    assigned_questions.submitted
  end

  # this is a utility routine to manually run for accounts
  def set_assignment_values
    self.update_column(:open_question_count, self.open_questions.count)
    self.update_column(:last_question_touched_at, self.initiated_question_events.order('created_at DESC').pluck(:created_at).first)
    self.update_column(:last_question_assigned_at, self.assigned_questions.order('created_at DESC').pluck(:created_at).first)
  end

  def daily_summary_group_list
    list = []
    self.groups.order("groups.name").each{|group| list.push(group) if (send_daily_summary?(group) and group.include_in_daily_summary?)}
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
    QuestionEvent.where("question_events.event_state IN (#{QuestionEvent::ASSIGNED_TO},#{QuestionEvent::AUTO_ASSIGNED_TO})").where("recipient_id = ?",self.id).minimum(:created_at)
  end

  def earliest_touched_at
    QuestionEvent.where("initiated_by_id = ?",self.id).minimum(:created_at)
  end

  def assigned_count_by_year
    QuestionEvent.where("question_events.event_state IN (#{QuestionEvent::ASSIGNED_TO},#{QuestionEvent::AUTO_ASSIGNED_TO})").where("recipient_id = ?",self.id).group("YEAR(created_at)").count('DISTINCT(question_id)')
  end

  def assigned_count_by_year_month
    QuestionEvent.where("question_events.event_state IN (#{QuestionEvent::ASSIGNED_TO},#{QuestionEvent::AUTO_ASSIGNED_TO})").where("recipient_id = ?",self.id).group("DATE_FORMAT(created_at,'%Y-%m')").count('DISTINCT(question_id)')
  end

  def assigned_list_for_year_month(year_month)
    year_month =~ /-/ ? date_string = '%Y-%m' : date_string = '%Y'
    Question.select("DISTINCT(questions.id), questions.*")
    .joins(:question_events)
    .where("question_events.event_state IN (#{QuestionEvent::ASSIGNED_TO},#{QuestionEvent::AUTO_ASSIGNED_TO})")
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

  def self.demographics_data_csv(filename)
    with_scope do
      _demographics_data_csv(filename)
    end
  end

  def self.demographics_private_data_csv(filename)
    with_scope do
      _demographics_data_csv(filename,true)
    end
  end

  def has_valid_email_regex?
    self.email =~ EMAIL_VALIDATION_REGEX ? true : false
  end

  def has_valid_email_mx?
    # from: https://github.com/hallelujah/valid_email/blob/master/lib/valid_email/mx_validator.rb
    # LICENSE: https://github.com/hallelujah/valid_email/blob/master/LICENSE
    begin
      m = Mail::Address.new(self.email)
      if m.domain
        mx = []
        Resolv::DNS.open do |dns|
          mx.concat dns.getresources(m.domain, Resolv::DNS::Resource::IN::MX)
        end
        r = mx.size > 0
      end
    rescue Mail::Field::ParseError
      false
    end
  end

  def self.check_for_invalid_emails(mxcheck = false)
    self.where("email is not NULL").find_each do |u|
      if(!u.has_valid_email_regex?)
        u.has_invalid_email = true
        u.invalid_email = u.email
        u.email = 'invalid_aae_email@extension.org'
        u.save
      elsif(mxcheck and !u.has_valid_email_mx?)
        u.has_invalid_email = true
        u.invalid_email = u.email
        u.email = 'invalid@extension.org'
        u.save
      end
    end
  end

  def self.pick_assignee_from_pool(users)
    user_pool = users.to_a
    if user_pool.blank? or user_pool.length == 0
      return nil
    end

    # look at question assignments to see who has the least for load balancing
    user_pool.sort! { |a, b| a.open_question_count <=> b.open_question_count }

    questions_floor = user_pool[0].open_question_count

    # who all matches the fewest number of questions assigned
    possible_user_pool = user_pool.select { |u| u.open_question_count == questions_floor }

    return nil if !possible_user_pool or possible_user_pool.length == 0
    return possible_user_pool[0] if possible_user_pool.length == 1

    # for the set of users with the same number of open questions, pick the person
    # out of the list with the oldest last assignment time
    possible_user_pool.sort! { |a, b| a.last_question_assigned_at(true) <=> b.last_question_assigned_at(true) }
    return possible_user_pool.first
  end

  def self.find_by_openid(uid_string)
    if !uid_string.blank? and user = self.where({:openid => uid_string}).first
      user
    else
      nil
    end
  end

  private

  def self._demographics_data_csv(filename,show_submitter = false)
    CSV.open(filename,'wb') do |csv|
      headers = []
      if(show_submitter)
        headers << 'submitter_id'
      end
      headers << 'submitter_is_extension'
      headers << 'demographics_count'
      demographic_columns = []
      AaeDemographicQuestion.order(:id).active.each do |adq|
        demographic_columns << "demographic_#{adq.id}"
      end
      headers += demographic_columns
      csv << headers

      # data
      # evaluation_answer_questions
      eligible_submitters = Question.demographic_eligible.pluck(:submitter_id).uniq
      response_submitters = Demographic.pluck(:user_id).uniq
      eligible_response_submitters = eligible_submitters & response_submitters
      self.where("id in (#{eligible_response_submitters.join(',')})").order("RAND()").each do |person|
        demographic_count = person.demographics.count
        next if (demographic_count == 0)
        row = []
        if(show_submitter)
          row << person.id
        end
        row << person.has_exid?
        row << demographic_count
        demographic_data = {}
        person.demographics.each do |demographic_answer|
          demographic_data["demographic_#{demographic_answer.demographic_question_id}"] = demographic_answer.response
        end

        demographic_columns.each do |column|
          row << demographic_data[column]
        end

        csv << row
      end
    end
  end

end
