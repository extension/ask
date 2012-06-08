class Authmap < ActiveRecord::Base
  devise :omniauthable
  belongs_to :user
  validates :authname, :uniqueness => {:scope => :source}
  
  
  def self.find_for_twitter_oauth(access_token, logged_in_user=nil)
    return process_user_info(access_token, logged_in_user)
  end
  
  def self.find_for_facebook_oauth(access_token, logged_in_user=nil)
    return process_user_info(access_token, logged_in_user)
  end
  
  def self.find_for_people_openid(access_token, logged_in_user=nil)
    return process_user_info(access_token, logged_in_user)
  end
  
  def self.find_for_google_openid(access_token, logged_in_user=nil)
    return process_user_info(access_token, logged_in_user)
  end
  
  # UPDATE: Will handle account merges manually (through a call from the console to the merge_account_with method on the user model) 
  # on a case by case basis for now
  # TODO: Logic needs to be changed here for account merge
  def self.process_user_info(access_token, logged_in_user)
    if !logged_in_user.blank?
      return logged_in_user
    end
    
    user_screen_name = access_token['uid']
    user_provider = access_token['provider']
    
    if authmap = Authmap.where({:authname => user_screen_name, :source => user_provider}).first
      return authmap.user
    end
    
    new_user = user.create
    new_user.email = access_token['info']['email'] if access_token['info']['email'].present?
    new_user.name = access_token['info']['name'] if access_token['info']['name'].present?
    new_user.authmaps << self.new(:authname => user_screen_name, :source => user_provider)
    new_user.save
    return new_user
  end
  
end
