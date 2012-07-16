class Group < ActiveRecord::Base
  has_many :group_connections, :dependent => :destroy  
  has_many :group_events
  has_many :questions
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
  
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  
  has_many :notifications, :as => :notifiable, dependent: :destroy
  has_many :notification_exceptions
  
  # will_paginate per page default 
  self.per_page = 15
  
  CONNECTIONS = {'member' => 'Community Member',
    'leader' => 'Community Leader',
    'wantstojoin' => 'Wants to Join Community',
    'invited' => 'Community Invitation'}
    
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
  
  
end
