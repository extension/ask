# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class WidgetController < ApplicationController
  #layout 'widgets'
  #has_rakismet :only => [:create_from_widget]
  #ssl_allowed :index, :create_from_widget


  # ask widget pulled from remote iframe
  def index
    @group = Group.find_by_widget_fingerprint(params[:fingerprint])

    if !@group.blank?
      if !@group.active?
        @status_message = "This widget has been disabled."
        return render(:template => '/widget/status', :layout => false)
      end
    else
      @status_message = "Unknown widget specified."
      return render(:template => '/widget/status', :layout => false)
    end

    @question = Question.new
    @question.images.build

    @host_name = request.host_with_port
    if(@group.is_bonnie_plants?)
      return render(:template => 'widget/bonnie_plants', :layout => false)
    else
      return render :layout => false
    end
  end

  def create_from_widget

  end

  def get_counties
    render :partial => "counties"
  end

end