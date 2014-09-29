class WidgetsController < ApplicationController
  
  def index
    @limit = 3
    @locations = Location.order('fipsid ASC')
    # create a unique widget div ID to use as a hook
    @widget_key = "aae-qw-" + SecureRandom.hex(4)
  end
  
  def generate_widget
    @widget_key = params[:widget_key]
    @widget_url = widgets_questions_url + ".js?" + params[:widget_params]
    respond_to do |format|
      format.js {render :generate_widget}
    end
  end
  
  def front_porch
    @question_list = Array.new
    group_array = Array.new
    
    @title = "eXtension Latest Resolved Questions"
    @path_to_questions = root_url
    @tag = Tag.find_by_name("front page")
    
    if (!@tag)
      @question_list = []
      return render "widgets"
    end
    
    if params[:limit].blank? || params[:limit].to_i <= 0
      question_limit = 5
    else
      question_limit = params[:limit].to_i
    end
    
    @question_list = Question.public_visible_answered.tagged_with(@tag.id).order('questions.updated_at DESC').limit(question_limit)
    
    if params[:width].blank? || params[:width].to_i <= 0
      @width = 300
    else
      @width = params[:width].to_i
    end
    
    render "widgets"
  end
  
  def answered
    if params[:limit].blank? || params[:limit].to_i <= 0
      question_limit = 5
    else
      question_limit = params[:limit].to_i
    end
    
    if params[:width].blank? || params[:width].to_i <= 0
      @width = 300
    else
      @width = params[:width].to_i
    end
    
    if request.format == Mime::JS
      # logging of widget use
      # referrer_url and widget fingerprint make a unique pairing
      referrer_url = request.referer
      if referrer_url.present?
        referrer_host = URI(referrer_url).host
      else
        referrer_url = nil 
        referrer_host = nil 
      end
      
      base_widget_url = "#{request.protocol}#{request.host_with_port}#{request.path}"
      widget_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
      widget_fingerprint = get_widget_fingerprint(params, base_widget_url)
    
      existing_widget_log = WidgetLog.where(widget_fingerprint: widget_fingerprint, referrer_url: referrer_url)
      if existing_widget_log.present?
        existing_widget_log.first.update_attribute(:load_count, existing_widget_log.first.load_count + 1)
      else
        WidgetLog.create(referrer_host: referrer_host, referrer_url: referrer_url, base_widget_url: base_widget_url, widget_url: widget_url, widget_fingerprint: widget_fingerprint, load_count: 1)
      end
      ##### End of Widget Logging
    end
    
    @title = "eXtension Latest Answered Questions"
    new_params = []
    
    if params[:group_id].present? && params[:group_id].to_i > 0 && group = Group.find_by_id(params[:group_id])
      question_group_scope = Question.from_group(group.id)
      @title += " from #{group.name}"
      new_params << "group_id=#{group.id}"
    else
      question_group_scope = Question.where({})
    end
    
    if params[:location].present? && params[:location].to_i > 0 && location = Location.find_by_id(params[:location])
      question_group_scope = question_group_scope.by_location(location)
      @title += " from #{location.name}"
      new_params << "location_id=#{location.id}"
    end
    
    if params[:county].present? && params[:county].to_i > 0 && county = County.find_by_id(params[:county])
      question_group_scope = question_group_scope.by_county(county)
      @title += " from #{county.name}"
      new_params << "county_id=#{county.id}"
    end
    
    if params[:tags].present?
      @tag_list = params[:tags].split(',')
      @title += " in #{@tag_list.join(',')}"
      if params[:operator].present?
        if params[:operator].downcase == 'and'
          @question_list = question_group_scope.public_visible_answered.tagged_with_all(@tag_list).order('resolved_at DESC').limit(question_limit)  
        end
      elsif params[:operator].blank? || params[:operator].downcase != 'and'
        @question_list = question_group_scope.public_visible_answered.tagged_with_any(@tag_list).order('COUNT(questions.id) DESC, resolved_at DESC').limit(question_limit)
      end
    else
      @question_list = question_group_scope.public_visible_answered.order('resolved_at DESC').limit(question_limit)
    end
    
    if @question_list.length == 0
      @title = "eXtension Latest Answered Questions"
      @tag = Tag.find_by_name("front page")
      @question_list = Question.public_visible_answered.tagged_with(@tag.id).order('questions.updated_at DESC').limit(question_limit)
    end
    
    @path_to_questions = questions_url + "?" + new_params.join("&")
    
    respond_to do |format|
      format.js {render :widgets}
    end
  end
  
  
  def questions
    new_params = []
    if params[:widget_key].present?
      @widget_key = params[:widget_key]
      new_params << "widget_key=#{@widget_key}"
    end
    
    if params[:limit].blank? || params[:limit].to_i <= 0
      question_limit = 5
    else
      question_limit = params[:limit].to_i
      new_params << "limit=#{question_limit}"
    end
    
    if params[:width].blank? || params[:width].to_i <= 0
      # @width = 300
    else
      @width = params[:width].to_i
      new_params << "width=#{@width}"
    end
    
    
    if request.format == Mime::JS
      # logging of widget use
      # referrer_url and widget fingerprint make a unique pairing
      referrer_url = request.referer
      if referrer_url.present?
        referrer_host = URI(referrer_url).host
      else
        referrer_url = nil 
        referrer_host = nil 
      end
      
      base_widget_url = "#{request.protocol}#{request.host_with_port}#{request.path}"
      widget_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
      widget_fingerprint = get_widget_fingerprint(params, base_widget_url)
    
      existing_widget_log = WidgetLog.where(widget_fingerprint: widget_fingerprint, referrer_url: referrer_url)
      if existing_widget_log.present?
        existing_widget_log.first.update_attribute(:load_count, existing_widget_log.first.load_count + 1)
      else
        WidgetLog.create(referrer_host: referrer_host, referrer_url: referrer_url, base_widget_url: base_widget_url, widget_url: widget_url, widget_fingerprint: widget_fingerprint, load_count: 1)
      end
      ##### End of Widget Logging
    end
    
    @title = ""
    
    if params[:group_id].present? && params[:group_id].to_i > 0 && group = Group.find_by_id(params[:group_id])
      question_group_scope = Question.from_group(group.id)
      @title += " from #{group.name}"
      new_params << "group_id=#{group.id}"
    else
      question_group_scope = Question.where({})
    end
    
    if params[:location_id].present? && params[:location_id].to_i > 0 && location = Location.find_by_id(params[:location_id])
      question_group_scope = question_group_scope.by_location(location)
      new_params << "location_id=#{location.id}"
      
      if params[:county_id].present? && params[:county_id].to_i > 0 && county = County.find_by_id(params[:county_id])
        question_group_scope = question_group_scope.by_county(county)
        @title += " from #{county.name}, #{location.name}"
        new_params << "county_id=#{county.id}"
      else
        @title += " from #{location.name}"
      end
    end
    
    if params[:tags].present?
      @tag_list = params[:tags].split(',')
      @title += " tagged #{@tag_list.join(',')}"
      if params[:operator].present?
        if params[:operator].downcase == 'and'
          @question_list = question_group_scope.public_visible_answered.tagged_with_all(@tag_list).order('resolved_at DESC').limit(question_limit)  
        end
      elsif params[:operator].blank? || params[:operator].downcase != 'and'
        @question_list = question_group_scope.public_visible_answered.tagged_with_any(@tag_list).order('COUNT(questions.id) DESC, resolved_at DESC').limit(question_limit)
      end
      new_params << "tags=#{params[:tags]}"
    else
      @question_list = question_group_scope.public_visible_answered.order('resolved_at DESC').limit(question_limit)
    end
    
    if @question_list.length == 0
      @no_matches = @title
      @title = "Ask an Expert Answers"
      @tag = Tag.find_by_name("front page")
      @question_list = Question.public_visible_answered.tagged_with(@tag.id).order('questions.updated_at DESC').limit(question_limit)
    else
      @title = "Ask an Expert Answers " + @title
    end
    
    @path_to_questions = questions_url + "?" + new_params.join("&")
    @widget_params = new_params.join("&")
    
    respond_to do |format|
      format.js {render :questions}
    end
  end
  
  private
  
  # fingerprint will be generated based on the widget's base url plus it's ordered parameters
  def get_widget_fingerprint(params_hash, base_widget_url)
    params_array = ['base_widget_url', base_widget_url]
  
    WidgetLog::KNOWN_PARAMS.each do |key|
      if(!params_hash[key].blank?)
        params_array << [key,params_hash[key].split(',').map{|i| i.strip.to_i}.sort]
      end
    end
    
    return Digest::SHA1.hexdigest(params_array.to_yaml)
  end
  
end
