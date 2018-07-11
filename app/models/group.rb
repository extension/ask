# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Group < ActiveRecord::Base
  include MarkupScrubber
  include TagUtilities

  # remove extra whitespace from these attributes
  auto_strip_attributes :name, :squish => true

  has_many :group_connections, dependent: :destroy
  has_many :group_events, dependent: :destroy
  has_many :assigned_question_events, :class_name => "QuestionEvent", :foreign_key => "recipient_group_id"
  has_many :questions, :class_name => "Question", :foreign_key => "assigned_group_id"
  has_many :group_locations, dependent: :destroy
  has_many :locations, :through => :group_locations
  has_many :group_counties, dependent: :destroy
  has_many :open_questions, :class_name => "Question", :foreign_key => "assigned_group_id", :conditions => "status_state = #{Question::STATUS_SUBMITTED}"
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :widget_location, :foreign_key => "widget_location_id", :class_name => "Location"
  belongs_to :widget_county, :foreign_key => "widget_county_id", :class_name => "County"

  has_many :users, :through => :group_connections

  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings

  has_many :notifications, :as => :notifiable, dependent: :destroy

  has_many :expertise_locations, :through => :group_locations, :source => :location
  has_many :expertise_counties, :through => :group_counties, :source => :county

  has_many :answered_questions, :class_name => "Question", :foreign_key => "assigned_group_id", :conditions => "questions.status_state = #{Question::STATUS_RESOLVED}"

  has_many :auto_assignment_logs

  validates :name, :presence => {:message => "Group name can't be blank"}
  validates :name,
    :uniqueness => {:message => "The name \"%{value}\" is being used by another group.", :case_sensitive => false},
    :unless => Proc.new { |a| a.name.blank? }

  scope :active, -> {where(group_active: true)}
  scope :inactive, -> {where(group_active: false)}
  scope :assignable, -> {active.where(is_test: false)}
  scope :test_groups, ->{where(is_test: true)}

  scope :with_expertise_county, lambda {|county_id| joins(:expertise_counties).where("group_counties.county_id = #{county_id}")}
  scope :with_expertise_location, lambda {|location_id| joins(:expertise_locations).where("group_locations.location_id = #{location_id}")}
  scope :with_expertise_location_all_counties, lambda {|location_id| joins(:expertise_counties).where("counties.location_id = #{location_id} AND counties.name = 'All'")}
  scope :tagged_with_any, lambda { |tag_array|
    tag_list = tag_array.map{|t| "'#{t.name}'"}.join(',')
    joins(:tags).select("#{self.table_name}.*, COUNT(#{self.table_name}.id) AS tag_count").where("tags.name IN (#{tag_list})").group("#{self.table_name}.id").order("tag_count DESC")
  }
  scope :tagged_with, lambda {|tag_id| includes(:taggings => :tag).where("tags.id = '#{tag_id}'").where("taggings.taggable_type = 'Group'")}

  scope :route_outside_locations, where(assignment_outside_locations: true)


  scope :order_by_assignee_count, lambda {
    joins(:users)
    .where('users.unavailable = ?',false).where("users.id NOT IN (#{User::SYSTEMS_USERS.join(',')})")
    .where('users.away = ?',false).where('users.auto_route = ?',true)
    .group('groups.id').order('COUNT(users.id) DESC') }


  scope :pattern_search, lambda {|searchterm, type = nil|
    # remove any leading * to avoid borking mysql
    # remove any '\' characters because it's WAAAAY too close to the return key
    # strip '+' and '?' characters because it's causing a repetition search error
    # strip parens '()' to keep it from messing up mysql query
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\?/,'').strip
    if sanitizedsearchterm == ''
      return {:conditions => 'false'}
    end

    if type.nil?
      where("name rlike ?", sanitizedsearchterm)
    elsif type == 'prefix'
      where("name rlike ?", "^#{sanitizedsearchterm}")
    end
  }

  has_attached_file :avatar, :styles => { :medium => "100x100#", :thumb => "40x40#", :mini => "20x20#" }, :url => "/uploads/:class/:attachment/:id_partition/:basename_:style.:extension"

  validates_attachment :avatar, :size => { :less_than => 8.megabytes },
    :content_type => { :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png'] }

  # pagination per page default
  paginates_per = 15

  # elasticsearch
  if(Settings.elasticsearch_enabled)
    update_index('groups#group') { self }
  end


  CONNECTIONS = {'member' => 'Group Member',
    'leader' => 'Group Leader'}

  # old connection hash, that might be useful for later functionality
  #CONNECTIONS = {'member' => 'Group Member',
  #  'leader' => 'Group Leader',
  #  'wantstojoin' => 'Wants to Join Group',
  #  'invited' => 'Group Invitation'}

  QUESTION_WRANGLER_GROUP_ID = 38
  EXTENSION_SUPPORT_GROUP_ID = 1278
  ORPHAN_GROUP_ID = 1

  # attr_writer override for description to scrub html
  def description=(descriptioncontent)
    write_attribute(:description, self.cleanup_html(descriptioncontent))
  end

  def joined
    users.valid_users
  end

  def leaders
    users.valid_users.where("group_connections.connection_type = ?",'leader')
  end

  def assignees
    users.valid_users.not_away.auto_route
  end

  def assignees_available?
    self.assignees.count > 0
  end

  def all_question_events
    QuestionEvent.where("recipient_group_id = #{self.id} or previous_group_id = #{self.id} or changed_group_id = #{self.id}")
  end

  def all_questions
    Question.where("assigned_group_id = #{self.id} or original_group_id = #{self.id}")
  end

  def deactivate_if_no_assignees
    if(self.assignees.count == 0)
      change_hash = Hash.new
      if self.group_active?
        self.toggle!(:group_active)
        change_hash[:group_active] = {:old => true, :new => false}
      end

      GroupEvent.log_edited_attributes(self, User.system_user, nil, change_hash)
      true
    else
      false
    end
  end

  def group_members_with_self_first(user, limit)
    group_members = self.joined.where("user_id != ?", user.id).order('connection_type ASC').order("users.last_activity_at DESC").limit(limit).to_a
    if (user.member_of_group(self))
      # push this person on the front of the list
      group_members = group_members.unshift(user)
    end
    group_members
  end

  def set_fingerprint(user)
    create_time = Time.now.to_s
    self.widget_fingerprint = Digest::SHA1.hexdigest(create_time + user.id.to_s + self.name)
  end

  def self.orphan_group
    self.find_by_id(ORPHAN_GROUP_ID)
  end

  def self.question_wrangler_group
    self.find_by_id(QUESTION_WRANGLER_GROUP_ID)
  end

  def add_expertise_county(county, added_by = User.system_user)
    county_id_list = self.group_counties.map(&:county_id)
    return if(county_id_list.include?(county.id)) # already connected, peace out
    all_county = county.location.get_all_county

    if(county.id == all_county.id)
      # delete all other county associations, no callbacks
      self.expertise_counties.delete_all
    elsif(self.is_primary_group_for_location?(county.location))
      # you can't add non-all county counties to a primary group for a location
      # so just bail from here
      return false
    else
      # delete all county if present
      if(all_county_connection = self.group_counties.where(county_id: all_county.id).first)
        # delete connection
        all_county_connection.delete
      end
    end

    # add the county
    self.group_counties.create(county_id: county.id)
    # add the location (don't care if it fails because it's already in that location)
    self.group_locations.create(location_id: county.location.id)

    #todo log
  end

  def remove_expertise_county(county, removed_by = User.system_user)
    #todo placeholder method
  end

  def add_expertise_location(location, added_by = User.system_user)
    #todo placeholder method
  end

  def remove_expertise_location(location, removed_by = User.system_user)
    #todo placeholder method
  end

  def is_primary_group_for_location?(location)
    if(group_location = self.group_locations.where(location_id: location.id).first)
      group_location.is_primary?
    else
      false
    end
  end

  def question_wrangler_group?
    self.id == QUESTION_WRANGLER_GROUP_ID
  end

  def include_in_daily_summary?
    self.open_questions.where("last_assigned_at < '#{Settings.aae_escalation_delta.hours.ago}'").empty? ? false : true
  end

  def incoming_notification_list(users_to_exclude=[])
    list = []
    self.joined.not_away.each{|assignee| list.push(assignee) if assignee.send_incoming_notification?(self.id)}
    if !users_to_exclude.nil?
      list = list - users_to_exclude
    end
    return list
  end

  def will_accept_question_location(question)
    (self.assignment_outside_locations or self.expertise_location_ids.include?(question.location_id))
  end

  def connect_user_to_group(user, connection_type, added_by = nil)
    added_by = user if(added_by.nil?)
    if(connection = self.group_connections.where(user_id: user.id).first)
      # existing connection? let's change the connection_type
      if(connection.connection_type != connection_type)
        connection.update_attribute(:connection_type, connection_type)
        if(connection_type == 'leader')
          GroupEvent.log_added_as_leader(self, added_by, user)
        else
          GroupEvent.log_removed_as_leader(self, added_by, user)
        end
      end
      return connection
    end

    if(connection = self.group_connections.create(user: user, connection_type: connection_type))
      if(connection_type == 'leader')
        GroupEvent.log_added_as_leader(self, added_by, user)
        Preference.create_or_update(user, Preference::NOTIFICATION_DAILY_SUMMARY, true, self.id) #leaders are opted into daily summaries / escalations
      else
        GroupEvent.log_group_join(self, added_by, user)
      end

      if(self.id == QUESTION_WRANGLER_GROUP_ID)
        user.update_attribute(:is_question_wrangler, true)
        Preference.create_or_update(user, Preference::NOTIFICATION_INCOMING, true, self.id)
      end

      return connection
    else
      return nil
    end
  end

  def remove_user_from_group(user, removed_by = nil)
    removed_by = user if(removed_by.nil?)
    self.group_connections.where(user_id: user.id).destroy_all
    if (user != removed_by)
      GroupEvent.log_group_remove(self, removed_by, user)
    else
      GroupEvent.log_group_leave(self, removed_by, user)
    end
    if(self.id == QUESTION_WRANGLER_GROUP_ID)
      user.update_attribute(:is_question_wrangler, false)
    end

    # update the person's listview prefererences
    pref = user.filter_preference
    if pref.present? && pref.setting[:question_filter][:groups].present? && pref.setting[:question_filter][:groups][0].to_i == self.id
      pref.setting[:question_filter].merge!({:groups => nil})
      pref.save
    end

    # check for empty group
    self.deactivate_if_no_assignees
  end

  def self.deactivate_if_no_assignees
    deactivated_list = []
    Group.active.each do |g|
      deactivated_list << g if g.deactivate_if_no_assignees
    end
    deactivated_list
  end

  def remove_if_inactive_or_test
    return false if(self.all_questions.count > 0)
    return false if(self.group_active? and !self.is_test?)
    # loop through any question events and handle the deleted group
    self.all_question_events.each do |qe|
      # these should be mutually exclusive
      if(!qe.recipient_group_id.nil? and qe.recipient_group_id == self.id)
        group_logs = qe.group_logs || {}
        group_logs[:recipient_group_name] = self.name
        qe.update_attributes(recipient_group_id: nil, group_logs: group_logs)
      elsif(!qe.previous_group_id.nil? and qe.previous_group_id == self.id)
        group_logs = qe.group_logs || {}
        group_logs[:previous_group_name] = self.name
        qe.update_attributes(previous_group_id: nil, group_logs: group_logs)
      elsif(!qe.changed_group_id.nil? and qe.changed_group_id == self.id)
        group_logs = qe.group_logs || {}
        group_logs[:changed_group_name] = self.name
        qe.update_attributes(changed_group_id: nil, group_logs: group_logs)
      end
    end
    self.destroy
    true
  end

  def self.asked_answered_metrics_for_date_range(start_date,end_date)
    asked_answered = {}
    asked    = Question.not_rejected \
               .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
               .group(:original_group_id) \
               .count('DISTINCT(questions.id)')


    asked_widget = Question.not_rejected \
                   .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
                   .where("questions.source = #{Question::FROM_WIDGET}")
                   .group(:original_group_id) \
                   .count('DISTINCT(questions.id)')

    moved_out = Question.not_rejected \
               .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
               .where('assigned_group_id != original_group_id')
               .group(:original_group_id) \
               .count('DISTINCT(questions.id)')

    moved_in = Question.not_rejected \
              .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
              .where('assigned_group_id != original_group_id')
              .group(:assigned_group_id) \
              .count('DISTINCT(questions.id)')

    moved_in_widget = Question.not_rejected \
              .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
              .where("questions.source = #{Question::FROM_WIDGET}")
              .where('assigned_group_id != original_group_id')
              .group(:assigned_group_id) \
              .count('DISTINCT(questions.id)')

    answered = Question.answered \
               .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
               .group(:assigned_group_id) \
               .count('DISTINCT(questions.id)')

    not_answered = Question.not_rejected \
                  .where("DATE(questions.created_at) >= ? and DATE(questions.created_at) <= ?",start_date.to_s,end_date.to_s) \
                  .where("status_state <> #{Question::STATUS_RESOLVED}")
                  .group(:assigned_group_id) \
                  .count('DISTINCT(questions.id)')


    Group.where(:is_test => false).each do |group|
      asked_answered[group] = {}
      asked_answered[group][:asked] = asked[group.id] || 0
      asked_answered[group][:asked_widget] = asked_widget[group.id] || 0
      asked_answered[group][:moved_out] = moved_out[group.id] || 0
      asked_answered[group][:moved_in] = moved_in[group.id] || 0
      asked_answered[group][:moved_in_widget] = moved_in_widget[group.id] || 0
      asked_answered[group][:answered] = answered[group.id] || 0
      asked_answered[group][:not_answered] = not_answered[group.id] || 0
    end

    asked_answered

  end

  def self.dump_asked_answered_metrics_for_date_range(filename,start_date,end_date)
    data = self.asked_answered_metrics_for_date_range(start_date,end_date)
    CSV.open(filename,'wb') do |csv|
      headers = []
      headers << 'id'
      headers << 'name'
      headers << 'is_test'
      headers << 'group_active'
      headers << 'assignment_outside_locations'
      headers << 'asked'
      headers << 'asked_from_widget'
      headers << 'moved_out'
      headers << 'moved_id'
      headers << 'moved_in_widget'
      headers << 'answered'
      headers << 'not_answered'
      headers << 'locations'
      csv << headers
      data.each do |group,values|
        row = []
        row << group.id
        row << group.name
        row << group.is_test
        row << group.group_active
        row << group.assignment_outside_locations
        row << values[:asked]
        row << values[:asked_widget]
        row << values[:moved_out]
        row << values[:moved_in]
        row << values[:moved_in_widget]
        row << values[:answered]
        row << values[:not_answered]
        row << group.locations.map(&:name).join(';')
        csv << row
      end
    end

  end

end
