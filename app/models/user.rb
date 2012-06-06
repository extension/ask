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
  
  has_attached_file :avatar, :styles => { :medium => "100x100>", :thumb => "50x50>" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  
  DEFAULT_NAME = 'Anonymous'
  
  
  def name
    return self.name if self.name.present? 
    return DEFAULT_NAME
  end
  
end
