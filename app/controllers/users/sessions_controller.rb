# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Users::SessionsController < Devise::SessionsController
  
  def new
    if session[:user_return_to].present? && (session[:user_return_to].include? '/expert/')
      redirect_to authmap_omniauth_authorize_path(:people, :redirect_to => (params[:redirect_to].present?) ? params[:redirect_to] : session[:user_return_to])
    end
  end

end