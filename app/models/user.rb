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
  
  has_attached_file :avatar, :styles => { :medium => "100x100#", :thumb => "40x40#" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  
  validates_attachment :avatar, :size => { :less_than => 2.megabytes },
    :content_type => { :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png'] }
  
  DEFAULT_NAME = 'Anonymous'
  scope :tagged_with, lambda {|tag_id| 
    {:include => {:taggings => :tag}, :conditions => "tags.id = '#{tag_id}' AND taggings.taggable_type = 'User'"}
  }
  
  scope :with_expertise_county, lambda {|county_id| {:include => :expertise_counties, :conditions => "user_counties.county_id = #{county_id}"}}
  scope :with_expertise_location, lambda {|location_id| {:include => :expertise_locations, :conditions => "user_locations.location_id = #{location_id}"}}
  
  scope :can_route_outside_location, lambda { |user_ids|
   location_routers = UserPreference.where("(name = '#{UserPreference::AAE_LOCATION_ONLY}' OR name = '#{UserPreference::AAE_COUNTY_ONLY}') AND (user_id IN (#{user_ids.join(',')}))").uniq.pluck('user_id').join(',')
   if location_routers.blank?
     {:conditions => "users.aae_responder = true", :order => "name ASC"}
   else
     {:conditions => "users.id NOT IN (#{location_routers}) AND users.aae_responder = true", :order => "name ASC"}
   end
  }
  
  def name
    return self[:name] if self[:name].present? 
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
      self.group_connections.create(group: group, connection_type: connection_type, connection_code: GroupEvent::GROUP_JOIN)
    else
      self.group_connections.create(group: group, connection_type: connection_type, connection_code: GroupEvent::GROUP_JOIN)
    end
  end
  
  def leave_group(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('connection_type = ?', connection_type).where('group_id = ?',group.id).first)
      connection.destroy
    end
  end
  
  def leave_group_leadership(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('connection_type = ?', connection_type).where('group_id = ?',group.id).first)
      connection.destroy
      self.group_connections.create(group: group, connection_type: "member", connection_code: GroupEvent::GROUP_JOIN)
    end
  end
  
end
