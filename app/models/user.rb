class User < ActiveRecord::Base
  has_many :authmaps
  has_many :comments
  has_many :questions
  has_many :responses
  has_many :user_locations
  has_many :user_counties
  has_many :user_preferences
  has_many :expertise_locations, :through => :user_locations, :source => :location
  has_many :expertise_counties, :through => :user_counties, :source => :county
  has_many :notification_exceptions
  has_many :group_connections, :dependent => :destroy
  has_many :group_memberships, :through => :group_connections, :source => :group, :conditions => "connection_type IN ('leader', 'member')", :order => "groups.name", :uniq => true
  has_many :ratings
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  has_many :initiated_question_events, :class_name => 'QuestionEvent', :foreign_key => 'initiated_by_id'
  has_many :answered_questions, :through => :initiated_question_events, :conditions => "question_events.event_state = #{QuestionEvent::RESOLVED}", :source => :question, :order => 'question_events.created_at DESC', :uniq => true
  has_many :open_questions, :class_name => "Question", :foreign_key => "assignee_id", :conditions => "status_state = #{Question::STATUS_SUBMITTED} AND spam = false"
  
  
  devise :rememberable, :trackable, :database_authenticatable
  
  has_attached_file :avatar, :styles => { :medium => "100x100#", :thumb => "40x40#", :mini => "20x20#" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  
  validates_attachment :avatar, :size => { :less_than => 8.megabytes },
    :content_type => { :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png'] }
  
  DEFAULT_NAME = 'Anonymous'
  scope :tagged_with, lambda {|tag_id| 
    {:include => {:taggings => :tag}, :conditions => "tags.id = '#{tag_id}' AND taggings.taggable_type = 'User'"}
  }
  
  scope :with_expertise_county, lambda {|county_id| {:include => :expertise_counties, :conditions => "user_counties.county_id = #{county_id}"}}
  scope :with_expertise_location, lambda {|location_id| {:include => :expertise_locations, :conditions => "user_locations.location_id = #{location_id}"}}
  scope :question_wranglers, conditions: { is_question_wrangler: true }
  
  scope :can_route_outside_location, lambda { |user_ids|
   location_routers = UserPreference.where("(name = '#{UserPreference::AAE_LOCATION_ONLY}' OR name = '#{UserPreference::AAE_COUNTY_ONLY}') AND (user_id IN (#{user_ids.join(',')}))").uniq.pluck('user_id').join(',')
   if location_routers.blank?
     {:conditions => "users.aae_responder = true", :order => "last_name ASC"}
   else
     {:conditions => "users.id NOT IN (#{location_routers}) AND users.aae_responder = true", :order => "last_name ASC"}
   end
  }
  
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
      return self[:first_name] + " " + self[:last_name][0,1]
    end
    return DEFAULT_NAME
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
    return self.darmok_id.present?
  end
  
  def retired?
    return self.retired
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
  
  def join_group(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('group_id = ?',group.id).first)
      connection.destroy
    end
    
    self.group_connections.create(group: group, connection_type: connection_type)
    
    if connection_type == 'leader'
      GroupEvent.create(created_by: self.id, recipient_id: self.id, description: GroupEvent::GROUP_EVENT_STRINGS[GroupEvent::GROUP_ADDED_AS_LEADER], event_code: GroupEvent::GROUP_ADDED_AS_LEADER, group: group)
    else
      GroupEvent.create(created_by: self.id, recipient_id: self.id, description: GroupEvent::GROUP_EVENT_STRINGS[GroupEvent::GROUP_JOIN], event_code: GroupEvent::GROUP_JOIN, group: group)
    end
    
    # question wrangler group?
    if(group.id == Group::QUESTION_WRANGLER_GROUP_ID)
      if(connection_type == 'leader' || connection_type == 'member')
        self.update_attribute(:is_question_wrangler, true)
      end
    end
    
  end
  
  def leave_group(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('connection_type = ?', connection_type).where('group_id = ?',group.id).first)
      connection.destroy
      GroupEvent.create(created_by: self.id, recipient_id: self.id, description: GroupEvent::GROUP_EVENT_STRINGS[GroupEvent::GROUP_LEFT], event_code: GroupEvent::GROUP_LEFT, group: group)
    end
    
    # question wrangler group?
    if(group.id == Group::QUESTION_WRANGLER_GROUP_ID)
      self.update_attribute(:is_question_wrangler, false)
    end
  end
  
  def leave_group_leadership(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('connection_type = ?', connection_type).where('group_id = ?',group.id).first)
      connection.destroy
      self.group_connections.create(group: group, connection_type: "member")
      GroupEvent.create(created_by: self.id, recipient_id: self.id, description: GroupEvent::GROUP_EVENT_STRINGS[GroupEvent::GROUP_REMOVED_AS_LEADER], event_code: GroupEvent::GROUP_REMOVED_AS_LEADER, group: group)
    end
  end
  
end
