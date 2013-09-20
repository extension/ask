class Authmap < ActiveRecord::Base
  devise :omniauthable
  belongs_to :user
  validates :authname, :uniqueness => {:scope => :source}
  
  
  def self.find_for_twitter_oauth(omniauth_auth_hash, logged_in_user=nil)
    return process_user_info(omniauth_auth_hash, logged_in_user)
  end
  
  def self.find_for_facebook_oauth(omniauth_auth_hash, logged_in_user=nil)
    return process_user_info(omniauth_auth_hash, logged_in_user)
  end
  
  def self.find_for_people_openid(omniauth_auth_hash, logged_in_user=nil)
    return process_user_info(omniauth_auth_hash, logged_in_user)
  end
  
  def self.find_for_google_openid(omniauth_auth_hash, logged_in_user=nil)
    return process_user_info(omniauth_auth_hash, logged_in_user)
  end
  
  # UPDATE: Will handle account merges manually (through a call from the console to the merge_account_with method on the user model) 
  # on a case by case basis for now
  # TODO: Logic needs to be changed here for account merge
  def self.process_user_info(omniauth_auth_hash, logged_in_user)
    if !logged_in_user.blank?
      return logged_in_user
    end
    
    user_screen_name = omniauth_auth_hash['uid']
    user_provider = omniauth_auth_hash['provider']
    
    # if it's an eXtension ID login, check and make sure they haven't logged in before the account has been populated by the account sync script
    if user_provider == 'people'
      user = User.find_by_email_and_kind(omniauth_auth_hash['info']['email'], 'User')
      return raise "The eXtension account being accessed has not yet been synced with AaE. Please try again in a few minutes. At most, it should take 15 minutes to complete." if user.nil?  
    end
    
    if authmap = Authmap.where({:authname => user_screen_name, :source => user_provider}).first
      return authmap.user
    end
    
    if omniauth_auth_hash['info']['email'].present?
      user = User.find_by_email(omniauth_auth_hash['info']['email'])
      if user.present?
        user.authmaps << self.new(:authname => user_screen_name, :source => user_provider)
        user.save
        return user
      end
    end
    
    new_user = User.create
    new_user.email = omniauth_auth_hash['info']['email'] if omniauth_auth_hash['info']['email'].present?
    new_user.public_name = omniauth_auth_hash['info']['name'] if omniauth_auth_hash['info']['name'].present?
    new_user.authmaps << self.new(:authname => user_screen_name, :source => user_provider)
    # the only kind of new user that can be created by logging in is a public user. the eXtension ID created account (People account), gets 
    # created by the People sync script, and eXtension ID holders are not allowed to login here unless their account exists here (ie. the sync script has created it here already)
    new_user.kind = 'PublicUser'
    
    new_user.save
    return new_user
  end
  
end
