class Group < ActiveRecord::Base
  has_many :group_connections, :dependent => :destroy  
  has_many :group_events
  has_many :question_events
  has_many :questions, :class_name => "Question", :foreign_key => "assigned_group_id"
  has_many :group_locations
  has_many :group_counties
  has_many :open_questions, :class_name => "Question", :foreign_key => "assigned_group_id", :conditions => "status_state = #{Question::STATUS_SUBMITTED}"
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :widget_location, :foreign_key => "widget_location_id", :class_name => "Location"
  belongs_to :widget_county, :foreign_key => "widget_county_id", :class_name => "County"
  
  has_many :users, :through => :group_connections
  has_many :validusers, :through => :group_connections, :source => :user, :conditions => "users.retired = 0"
  has_many :joined, :through => :group_connections, :source => :user, :conditions => "(group_connections.connection_type = 'member' OR group_connections.connection_type = 'leader') and users.retired = 0"
  has_many :members, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'member' and users.retired = 0"
  has_many :leaders, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'leader' and users.retired = 0"
  has_many :assignees, :through => :group_connections, :source => :user, :conditions => "(group_connections.connection_type = 'member' OR group_connections.connection_type = 'leader') and users.retired = 0 and users.away = 0 and users.auto_route = 1"
  # these are not relevant right now, but we might use some of this in the future
  # has_many :invited, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'invited' and users.retired = 0"
  # has_many :interest, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'interest' and users.retired = 0"
  # has_many :interested, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type IN ('interest','wantstojoin','leader') and users.retired = 0"
  # has_many :wantstojoin, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'wantstojoin' and users.retired = 0"
  
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  
  has_many :notifications, :as => :notifiable, dependent: :destroy
  has_many :notification_exceptions
  
  has_many :expertise_locations, :through => :group_locations, :source => :location
  has_many :expertise_counties, :through => :group_counties, :source => :county
  
  has_many :answered_questions, :class_name => "Question", :foreign_key => "assigned_group_id", :conditions => "questions.status_state = #{Question::STATUS_RESOLVED}"

  validates :name, :presence => {:message => "Group name can't be blank"}
  validates :name, 
    :uniqueness => {:message => "The name \"%{value}\" is being used by another group.", :case_sensitive => false}, 
    :unless => Proc.new { |a| a.name.blank? }
  
  scope :public_visible, where(is_test: false, widget_active: true, group_active: true)
  scope :assignable, conditions: {is_test: false, group_active: true}

  scope :with_expertise_county, lambda {|county_id| joins(:expertise_counties).where("group_counties.county_id = #{county_id}")}
  scope :with_expertise_location, lambda {|location_id| joins(:expertise_locations).where("group_locations.location_id = #{location_id}")}
  scope :with_expertise_location_all_counties, lambda {|location_id| joins(:expertise_counties).where("counties.location_id = #{location_id} AND counties.name = 'All'")}
  scope :tagged_with_any, lambda { |tag_array|
    tag_list = tag_array.map{|t| "'#{t.name}'"}.join(',') 
    joins(:tags).select("#{self.table_name}.*, COUNT(#{self.table_name}.id) AS tag_count").where("tags.name IN (#{tag_list})").group("#{self.table_name}.id").order("tag_count DESC") 
  }
  scope :tagged_with, lambda {|tag_id| includes(:taggings => :tag).where("tags.id = '#{tag_id}'").where("taggings.taggable_type = 'Group'")}
  
  scope :route_outside_locations, where(assignment_outside_locations: true)
  
  scope :pattern_search, lambda {|searchterm, type = nil|
    # remove any leading * to avoid borking mysql
    # remove any '\' characters because it's WAAAAY too close to the return key
    # strip '+' characters because it's causing a repitition search error
    # strip parens '()' to keep it from messing up mysql query
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').strip
    if sanitizedsearchterm == ''
      return {:conditions => 'false'}
    end
    
    if type.nil?
      where("name rlike ?", sanitizedsearchterm)
    elsif type == 'prefix'
      where("name rlike ?", "^#{sanitizedsearchterm}")
    end
  }
  
  has_attached_file :avatar, :styles => { :medium => "100x100#", :thumb => "40x40#", :mini => "20x20#" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  
  validates_attachment :avatar, :size => { :less_than => 8.megabytes },
    :content_type => { :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png'] }
    
  # sunspot/solr search
  searchable do
    text :name
    text :description
  end
    
  # pagination per page default 
  paginates_per = 15
  
  CONNECTIONS = {'member' => 'Group Member',
    'leader' => 'Group Leader'}
  
  # old connection hash, that might be useful for later functionality  
  #CONNECTIONS = {'member' => 'Group Member',
  #  'leader' => 'Group Leader',
  #  'wantstojoin' => 'Wants to Join Group',
  #  'invited' => 'Group Invitation'}
    
  QUESTION_WRANGLER_GROUP_ID = 38
  ORPHAN_GROUP_ID = 1
    
  # hardcoded for widget layout difference
  BONNIE_PLANTS_GROUP = '4856a994f92b2ebba3599de887842743109292ce'

  # hardcoded for support purposes
  SUPPORT_WIDGET_FINGERPRINT = '7ae729bf767d0b3165ddb2b345491f89533a7b7b'
  
  # hardcoded for engineering-direct support purposes
  ENGINEERING_GROUP_FINGERPRINT = 'ce3269eb3049931445262589195b56ce7aefb6f8'

  def self.support_group
    self.find_by_widget_fingerprint(SUPPORT_WIDGET_FINGERPRINT)
  end

  def self.engineering_group
    self.find_by_widget_fingerprint(ENGINEERING_GROUP_FINGERPRINT)
  end
  
  def is_bonnie_plants?
    (self.widget_fingerprint == BONNIE_PLANTS_GROUP)
  end
  
  def group_members_with_self_first(current_user, limit)
    group_members = self.joined.where("user_id != ?", current_user.id).limit(limit)
    if (current_user.leader_of_group(self) || current_user.member_of_group(self))
      group_members = group_members.unshift(current_user)
    end
    return group_members
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
  
  def self.get_wrangler_assignees(question_location = nil, question_county = nil)
    assignees = nil
    wrangler_group = self.question_wrangler_group
    
    if question_county.present?
      assignees = wrangler_group.assignees.with_expertise_county(question_county.id)
    end
    
    if assignees.blank? && question_location.present?
      assignees = wrangler_group.assignees.with_expertise_location(question_location.id)
    end
    
    if assignees.blank?
      assignees = wrangler_group.assignees.active.route_from_anywhere
    end
    
    return assignees
  end
  
  def question_wrangler_group?
    self.id == QUESTION_WRANGLER_GROUP_ID
  end
  
  def set_tag(tag)
    if self.tags.collect{|t| Tag.normalizename(t.name)}.include?(Tag.normalizename(tag))
      return false
    else 
      if(tag = Tag.find_or_create_by_name(Tag.normalizename(tag)))
        self.tags << tag
        return tag
      end
    end
  end
  
  def include_in_daily_summary?
    self.open_questions.where("last_assigned_at < '#{Settings.aae_escalation_delta.hours.ago}'").empty? ? false : true
  end
  
  def incoming_notification_list(users_to_exclude=[])
    list = []
    self.members.each{|member| list.push(member) if member.send_incoming_notification?(self.id)}
    if !users_to_exclude.nil?
      list = list - users_to_exclude
    end
    return list
  end
  
end
