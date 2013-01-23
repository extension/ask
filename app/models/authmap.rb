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
      # what we're doing here is if someone say logs in with facebook and has a public account, then goes back and gets 
      # an eXtension ID (using the same email address), then we do not want to use the same public user record that was associated with the facebook account, 
      # we want to use their eXtension user record that was auto-populated from the sync script. 
      # we will look for the user record of kind 'User' and a matching email address to make sure we have the correct account if they are logging in w/ People.
      # right now, there is no way to merge the two accounts into one.
      # The other way around, if someone has an eXtension account first, and then logs in with say facebook (w/ same email address), then the eXtension ID 
      # user record will be used and the facebook authmap will get associated with that account (user record) so the same user record will be used for both.
      if user_provider == 'people'
        user = User.find_by_email_and_kind(omniauth_auth_hash['info']['email'], 'User')
      else
        user = User.find_by_email(omniauth_auth_hash['info']['email'])
      end
      
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
