class Group < ActiveRecord::Base
  has_many :group_connections, :dependent => :destroy  
  has_many :group_events
  has_many :questions
  has_many :group_locations
  has_many :group_counties
  has_many :open_questions, :class_name => "Question", :foreign_key => "assigned_group_id", :conditions => "status_state = #{Question::STATUS_SUBMITTED} AND spam = false"
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :widget_location, :foreign_key => "widget_location_id", :class_name => "Location"
  belongs_to :widget_county, :foreign_key => "widget_county_id", :class_name => "County"
  
  has_many :users, :through => :group_connections
  has_many :validusers, :through => :group_connections, :source => :user, :conditions => "users.retired = 0"
  has_many :wantstojoin, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'wantstojoin' and users.retired = 0"
  has_many :joined, :through => :group_connections, :source => :user, :conditions => "(group_connections.connection_type = 'member' OR group_connections.connection_type = 'leader') and users.retired = 0"
  has_many :members, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'member' and users.retired = 0"
  has_many :leaders, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'leader' and users.retired = 0"
  has_many :invited, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'invited' and users.retired = 0"
  has_many :interest, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type = 'interest' and users.retired = 0"
  has_many :interested, :through => :group_connections, :source => :user, :conditions => "group_connections.connection_type IN ('interest','wantstojoin','leader') and users.retired = 0"
  has_many :assignees, :through => :group_connections, :source => :user, :conditions => "(group_connections.connection_type = 'member' OR group_connections.connection_type = 'leader') and users.retired = 0 and users.aae_responder = 1"
  
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  
  has_many :notifications, :as => :notifiable, dependent: :destroy
  has_many :notification_exceptions
  
  has_many :expertise_locations, :through => :group_locations, :source => :location
  has_many :expertise_counties, :through => :group_counties, :source => :county
  
  has_many :answered_questions, :class_name => "Question", :foreign_key => "assigned_group_id", :conditions => "questions.status_state = #{Question::STATUS_RESOLVED} AND questions.spam = false"
  
  # will_paginate per page default 
  self.per_page = 15
  
  CONNECTIONS = {'member' => 'Community Member',
    'leader' => 'Community Leader',
    'wantstojoin' => 'Wants to Join Community',
    'invited' => 'Community Invitation'}
    
  QUESTION_WRANGLER_GROUP_ID = 38
    
  # hardcoded for widget layout difference
  BONNIE_PLANTS_GROUP = '4856a994f92b2ebba3599de887842743109292ce'

  # hardcoded for support purposes
  SUPPORT_GROUP = '7ae729bf767d0b3165ddb2b345491f89533a7b7b'
  
  def self.support_group
    self.find_by_widget_fingerprint(SUPPORT_GROUP)
  end
  
  def is_bonnie_plants?
    (self.widget_fingerprint == BONNIE_PLANTS_GROUP)
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
      assignees = wrangler_group.assignees.can_route_outside_location(wrangler_group.assignees.map{|ga| ga.id})
    end
    
    return assignees
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
  
end
