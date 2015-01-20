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
      if !@group.widget_active?
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

  def js_widget
    @group = Group.find_by_widget_fingerprint(params[:fingerprint])
    if @widget_parent_url.blank?
      if params[:widget_parent_url].present?
        @widget_parent_url = params[:widget_parent_url]
      else
        @widget_parent_url = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
      end
    end

    if !@group.blank?
      if !@group.widget_active?
        @status_message = "This widget has been disabled."
        return render(:template => '/widget/status', :layout => false)
      end
    else
      @status_message = "Unknown widget specified."
      return render(:template => '/widget/status', :layout => false)
    end

    @question = Question.new
    # display three image fields for question submitter
    3.times do
      @question.images.build
    end

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

  def ajax_counties
    counties = County.where(:location_id => params[:location_id])
    list = counties.map {|c| Hash[ id: c.id, label: c.name, name: c.name]}
    render json: list, callback: params[:callback]
  end

end
