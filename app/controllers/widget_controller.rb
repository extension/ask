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

  def create_from_widget

  end

  def get_counties
    render :partial => "counties"
  end

  def ajax_counties
    if params[:term]
      like= "%".concat(params[:term].concat("%"))
      counties = County.where("name like ?", like).where(:location_id => params[:location_id])
    else
      counties = County.where(:location_id => params[:location_id])
    end
    list = counties.map {|c| Hash[ id: c.id, label: c.name, name: c.name]}
    # render json: list
    render json: list, callback: params[:callback]
  end

  def get_counties_list
    render :partial => "counties"
    respond_to do |format|
      # shows the widget generator form for the client
      format.html
      # deliver the bootstrapping Javascript
      # format.js { render "bootstrap", formats: [:js] }
      # deliver the rendered events as JSONP response to the widget
      format.json {
        search = Search.new(q: params[:q], per: params[:limit])
        # render json: search.events, callback: params[:callback]
        render :json => response.to_json, :callback => params['callback']
      }
    end
  end

end
