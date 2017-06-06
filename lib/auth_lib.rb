# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module AuthLib

  def current_user
    if(!@current_user)
      if(session[:user_id])
        @current_user = Learner.find_by_id(session[:user_id])
      end
    end

    if(@current_user and !@current_user.signin_allowed?)
      @current_user = nil
      nil
    else
      @current_user
    end
  end

  def set_current_user(user)
    if(user.blank?)
      @current_user = nil
      reset_session
    elsif(!user.signin_allowed?)
      @current_user = nil
      reset_session
    else
      @current_user = user
      session[:user_id] = user.id
    end
  end

  private


  def signin_required
    if session[:user_id]
      user = Learner.find_by_id(session[:user_id])
      if (user.signin_allowed?)
        set_current_user(user)
        return true
      else
        set_current_user(nil)
        return redirect_to(root_url)
      end
    end

    # store current location so that we can
    # come back after the user logged in
    store_location
    access_denied
    return false
  end


  def signin_optional
    if session[:user_id]
      user = User.find_by_id(session[:user_id])
      if (user.signin_allowed?)
        set_current_user(user)
      end
    end
    return true
  end

  def access_denied
    redirect_to '/auth/people'
  end


  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    session[:return_to] = request.fullpath
    true
  end

  def clear_location
    session[:return_to] = nil
    true
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      redirect_to default
    else
      redirect_to session[:return_to]
      session[:return_to] = nil
    end
  end


  def admin_signin_required
    if session[:user_id]
      user = user.find_by_id(session[:user_id])
      if (user.signin_allowed? and user.is_admin?)
        set_current_user(user)
        return true
      else
        set_current_user(nil)
        return redirect_to(:controller => '/notice', :action => 'admin_required')
      end
    end

    # store current location so that we can
    # come back after the user logged in
    store_location
    access_denied
    return false
  end

end
