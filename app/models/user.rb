class User < ActiveRecord::Base
  has_many :authmaps
  has_many :comments
  has_many :questions
  has_many :responses
  has_many :locations
  has_many :counties
  has_many :notification_exceptions
  has_many :group_connections, :dependent => :destroy
  has_many :ratings
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  has_many :initiated_question_events, :class_name => 'QuestionEvent', :foreign_key => 'initiated_by_id'
  has_many :answered_questions, :through => :initiated_question_events, :conditions => "question_events.event_state = #{QuestionEvent::RESOLVED}", :source => :question, :order => 'question_events.created_at DESC', :uniq => true
  
  devise :rememberable, :trackable, :database_authenticatable
  
  has_attached_file :avatar, :styles => { :medium => "100x100#", :thumb => "40x40#" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  
  validates_attachment :avatar, :size => { :less_than => 2.megabytes },
    :content_type => { :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png'] }
  
  DEFAULT_NAME = 'Anonymous'
  
  
  def name
    return self[:name] if self[:name].present? 
    return DEFAULT_NAME
  end
  
  def self.systemuserid
    return 1
  end
  
  def has_exid?
    return self.darmok_id.present?
  end
  
end
