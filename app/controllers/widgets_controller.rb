class WidgetsController < ApplicationController
  
  def front_porch
    @question_list = Array.new
    group_array = Array.new
    
    @title = "eXtension Latest Resolved Questions"
    @path_to_questions = root_url
    questions = Question.public_visible_answered.featured.order('featured_at DESC')
    
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
    
    if questions.length == 0
      @question_list = []
    else
      questions.each do |q|
        assigned_group = q.assigned_group
        @question_list << q if (!group_array.include?(assigned_group.id) || assigned_group.blank?)
        break if (@question_list.length == question_limit || @question_list.length == questions.length)
        if assigned_group.present? 
          group_array << assigned_group.id
        end
      end
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
    
    # logging of widget use
    # referrer_url and widget fingerprint make a unique pairing
    referrer_url = request.referer
    referrer_host = URI(referrer_url).host
    base_widget_url = "#{request.protocol}#{request.host_with_port}#{request.path}"
    widget_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    widget_fingerprint = get_widget_fingerprint(params, base_widget_url)
    
    existing_widget_log = WidgetLog.where(widget_fingerprint: widget_fingerprint, referrer_url: referrer_url)
    if existing_widget_log.present?
      existing_widget_log.first.update_attribute(:count, existing_widget_log.count + 1)
    else
      WidgetLog.create(referrer_host: referrer_host, referrer_url: referrer_url, base_widget_url: base_widget_url, widget_url: widget_url, widget_fingerprint: widget_fingerprint, count: 1)
    end
    ##### End of Widget Logging
    
    if params[:group_id].present? && params[:group_id].to_i > 0 && group = Group.find_by_id(params[:group_id])
      question_group_scope = Question.from_group(group.id)
      @path_to_questions = group_url(group.id)
    else
      question_group_scope = Question.where({})
      @path_to_questions = root_url
    end
      
    if params[:tags].present?  
      @tag_list = params[:tags].split(',')
      @title = "eXtension Latest Resolved Questions in #{@tag_list.join(',')}"
      if params[:operator].present?
        if params[:operator].downcase == 'and'
          @question_list = question_group_scope.public_visible_answered.tagged_with_all(@tag_list).order('resolved_at DESC').limit(question_limit)  
        end
      elsif params[:operator].blank? || params[:operator].downcase != 'and'
        @question_list = question_group_scope.public_visible_answered.tagged_with_any(@tag_list).order('COUNT(questions.id) DESC, resolved_at DESC').limit(question_limit)
      end
    else
      if group.present?
        @title = "eXtension Latest Resolved Questions from Group #{group.name}"
      else
        @title = "eXtension Latest Resolved Questions"
      end
      @question_list = question_group_scope.public_visible_answered.order('resolved_at DESC').limit(question_limit)
    end
    
    render "widgets"
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
