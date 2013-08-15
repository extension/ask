class Authmaps::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :set_yolo
  def twitter
    @user = Authmap.find_for_twitter_oauth(env["omniauth.auth"], current_user)
    if @user.persisted?
      if @user.retired == false
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Twitter"
      else
        return redirect_to users_retired_url
      end
      
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.twitter_data"] = env["omniauth.auth"].except('extra')
      redirect_to new_user_session_url
    end
  end
  
  def facebook
    @user = Authmap.find_for_facebook_oauth(env["omniauth.auth"], current_user)
    if @user.persisted?
      if @user.retired == false
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook"
      else
        return redirect_to users_retired_url
      end
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.facebook_data"] = env["omniauth.auth"]
      redirect_to new_user_session_url
    end
  end
  
  def people
    begin
      @user = Authmap.find_for_people_openid(env["omniauth.auth"], current_user)
    rescue Exception => e
      flash[:error] = "Error Authenticating: #{e}"  
      return redirect_to new_user_session_url
    end
    
    if @user.persisted?
      if @user.retired == false
        if params[:redirect_to].present? && (params[:redirect_to].include? '/expert/')
          # don't indicate a successful login because the user never clicked a "sign in" button
        else
          flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "eXtension"
        end
      else
        return redirect_to users_retired_url
      end
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.people_data"] = env["omniauth.auth"]
      redirect_to new_user_session_url
    end
  end
  
  def google
    @user = Authmap.find_for_google_openid(env["omniauth.auth"], current_user)
    if @user.persisted?
      if @user.retired == false
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      else
        return redirect_to users_retired_url
      end
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.google_data"] = env["omniauth.auth"]
      redirect_to new_user_session_url
    end
  end
  
  def failure
    flash[:notice] = "Access denied. Please try again."
    redirect_to new_user_session_url
    return
  end
  
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
end