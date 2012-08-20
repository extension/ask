class User < ActiveRecord::Base
  has_many :authmaps
  has_many :comments
  has_many :questions
  has_many :responses
  has_many :user_locations
  has_many :user_counties
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
  
  scope :with_expertise_county, lambda {|county_id| {:include => :expertise_counties, :conditions => "user_counties.county_id = #{county_id}"}}
  scope :with_expertise_location, lambda {|location_id| {:include => :expertise_locations, :conditions => "user_locations.location_id = #{location_id}"}}
  
  scope :can_route_outside_location, lambda { |user_ids|
   location_routers = UserPreference.where("(name = '#{UserPreference::AAE_LOCATION_ONLY}' OR name = '#{UserPreference::AAE_COUNTY_ONLY}') AND (user_id IN (#{user_ids.join(',')}))").uniq.pluck('user_id').join(',')
   {:conditions => "users.id NOT IN (#{location_routers}) AND users.aae_responder = true", :order => "name ASC"}
  }
  
  def name
    return self[:name] if self[:name].present? 
    return DEFAULT_NAME
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
  
  def set_tag(tag)
    if(tag = Tag.find_or_create_by_name(tag))
      self.tags << tag
    end  
  end
  
end
