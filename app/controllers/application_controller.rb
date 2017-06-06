# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ApplicationController < ActionController::Base
  include AuthLib
  helper_method :current_user

  protect_from_forgery
  layout "public"

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES','y','Y']
  FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO','n','N']

  helper_method :current_location
  helper_method :current_county
  helper_method :time_period_to_s
  helper_method :humanize_bytes
  helper_method :location_names
  helper_method :location_abbreviations
  helper_method :county_names

  before_filter :set_time_zone_from_user
  before_filter :set_last_active_at_for_user
  before_filter :check_unavailable
  before_filter :set_yolo
  before_filter :set_referer_track

  # identify the culprit of the papertrail revisions, it's either someone logged in that creates or edits a question or someone from the public who has a user record created and associated with them
  def user_for_paper_trail
    current_user.present? ? current_user.id : session[:submitter_id]
  end

  def append_info_to_payload(payload)
    super
    payload[:ip] = request.remote_ip
    payload[:auth_id] = current_user.id if current_user
  end

  # additional tracking information for papertrail
  def info_for_paper_trail
    { :ip_address => request.remote_ip, :reason => params[:reason], :notify_submitter => params[:notify_submitter].present? ? params[:notify_submitter] : false }
  end

  # turn off paper trail on the create action. we have it configured for updates only, but somehow papertrail is detecting an update on body and title (thus generating a new revision) on create
  def paper_trail_enabled_for_controller
    params[:action] != 'create' && params[:action] != 'ask' && params[:action] != 'answer'
  end

  def record_not_found
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end

  def set_yolo
    if(!@yolo)
      @yolo = YoLo.new(request.remote_ip,session)
    end
  end

  def current_location
    if(!@yolo)
      set_yolo
    end
    @yolo.nil? ? nil : @yolo.location
  end

  def current_county
    if(!@yolo)
      set_yolo
    end
    @yolo.nil? ? nil : @yolo.county
  end

  def set_time_zone_from_user
    if(current_user)
      Time.zone = current_user.time_zone
    else
      Time.zone = Settings.default_display_timezone
    end
    true
  end

  def set_last_active_at_for_user
    if current_user
      if current_user.last_active_at != Date.today
        current_user.update_attribute(:last_active_at, Date.today)
      end
    end
    return true
  end

  def check_unavailable
    if current_user && current_user.unavailable
      return sign_out current_user
    end
  end

  def filtered_questions
    condition_array = Array.new
    filter_description_array = Array.new

    if params[:status].present?
      @status = params[:status]
      if @status == "answered"
        filter_description_array << "Answered"
      elsif @status == "unanswered"
        filter_description_array << "Needs an Answer"
      elsif @status == "autorejects"
        filter_description_array << "Automatically Rejected"
      else
        # all questions
      end
    end

    if params[:county_id].present?
      @county = County.find_by_id(params[:county_id])
      @county_pref = @county.id
      condition_array << "questions.county_id = #{@county.id}"
      filter_description_array << "#{@county.name}"
    end

    if params[:location_id].present?
      @location = Location.find_by_id(params[:location_id])
      @location_pref = @location.id
      condition_array << "questions.location_id = #{@location.id}"
      filter_description_array << "#{@location.name}"
    end

    if params[:group_id].present?
      @group = Group.find_by_id(params[:group_id])
      @group_pref = @group.id
      condition_array << "questions.assigned_group_id = #{@group.id}"
      filter_description_array << "Group: #{@group.name}"
    end

    if params[:expert_location_id].present?
      @expert_location = Location.find_by_id(params[:expert_location_id])
      @expert_location_pref = @expert_location.id
      condition_array << "users.location_id = #{@expert_location.id}"
      filter_description_array << "Expert Location: #{@expert_location.name}"
    end

    q = Question

    if params[:privacy].present?
      @privacy = params[:privacy]
    end

    if @privacy == 'public'
      filter_description_array << "Public"
      q = q.public_visible
    elsif @privacy == 'switched_to_private'
      filter_description_array << "Switched to Private"
      q = q.switched_to_private
    elsif @privacy == 'private'
      filter_description_array << "Private"
      q = q.not_public_visible
    end

    if(params[:tag_id].present? and @tag = Tag.find_by_id(params[:tag_id]))
      @tag_pref = @tag.id
      filter_description_array << "Tag: #{@tag.name}"
      q = q.tagged_with(@tag.id)
    elsif params[:tags].present?
      @tag_list = params[:tags].split(',')
      if params[:operator].present?
        if params[:operator].downcase == 'and'
          q = q.tagged_with_all(@tag_list)
          filter_description_array << "Tags: #{@tag_list.join(" and ")}"
        end
      elsif params[:operator].blank? || params[:operator].downcase != 'and'
        q = q.tagged_with_any(@tag_list)
        filter_description_array << "Tags: #{@tag_list.join(" or ")}"
      end
    end

    if @expert_location
      q = q.joins(:assignee)
    end

    condition_array.empty? ? condition_string = nil : condition_string = condition_array.join(' AND ')
    filter_description_array.empty? ? @filter_string = nil : @filter_string = filter_description_array.join(' | ')

    if @status == 'answered'
      return q.answered.where(condition_string).order("questions.resolved_at DESC").page(params[:page])
    elsif @status == 'unanswered'
      return q.submitted.where(condition_string).order("questions.created_at DESC").page(params[:page])
    elsif @status == 'autorejected'
      return q.auto_rejected.where(condition_string).order("questions.created_at DESC").page(params[:page])
    else
      return q.where(condition_string).order("questions.created_at DESC").page(params[:page])
    end

  end

  # Takes a period of time in seconds and returns it in human-readable form (down to minutes)
  # code from http://www.postal-code.com/binarycode/2007/04/04/english-friendly-timespan/
  def time_period_to_s(time_period,abbreviated=false,defaultstring='')
   return defaultstring if time_period.blank?
   out_str = ''
   interval_array = [ [:weeks, 604800], [:days, 86400], [:hours, 3600], [:minutes, 60], [:seconds, 1] ]
   interval_array.each do |sub|
    if time_period >= sub[1] then
      time_val, time_period = time_period.divmod( sub[1] )
      if(abbreviated)
        name = sub[0].to_s.first
        ( sub[0] != :seconds ? out_str += ", " : out_str += " " ) if out_str != ''
      else
        time_val == 1 ? name = sub[0].to_s.chop : name = sub[0].to_s
        ( sub[0] != :seconds ? out_str += ", " : out_str += " and " ) if out_str != ''
      end
      out_str += time_val.to_i.to_s + " #{name}"
    end
   end
   if(out_str.nil? or out_str.empty?)
     return defaultstring
   else
     return out_str
   end
  end


  # code from: https://github.com/ripienaar/mysql-dump-split
  def humanize_bytes(bytes,defaultstring='')
    if(!bytes.nil? and bytes != 0)
      units = %w{B KB MB GB TB}
      e = (Math.log(bytes)/Math.log(1024)).floor
      s = "%.1f"%(bytes.to_f/1024**e)
      s.sub(/\.?0*$/,units[e])
    else
      defaultstring
    end
  end

  def location_names(cache_options = {})
    Rails.cache.fetch('location_names', cache_options) do
      Hash[Location.all.map{|l| [l.id,l.name]}]
    end
  end

  def location_abbreviations(cache_options = {})
    Rails.cache.fetch('location_names', cache_options) do
      Hash[Location.all.map{|l| [l.id,l.abbreviation]}]
    end
  end

  def county_names(cache_options = {})
    Rails.cache.fetch('county_names', cache_options) do
      Hash[County.all.map{|l| [l.id,l.name]}]
    end
  end

  def http_referer_uri
    request.env["HTTP_REFERER"] && URI.parse(request.env["HTTP_REFERER"])
  end

  def refered_from_our_site?
    if uri = http_referer_uri
      uri.host == request.host
    end
  end

  def set_referer_track
    # ignore bots
    return true if request.bot?

    # ignore StatusCake
    return true if(request.env['HTTP_USER_AGENT'] =~ %r{StatusCake}i)

    if(session[:rt] and referer_track = RefererTrack.where(id: session[:rt]).first)
      referer_track.increment!(:load_count)
    else
      referer_track = RefererTrack.create(ipaddr: request.remote_ip,
                                          referer: request.env["HTTP_REFERER"],
                                          user_agent: request.env['HTTP_USER_AGENT'],
                                          landing_page: "#{request.protocol}#{request.host_with_port}#{request.fullpath}")
      session[:rt] = referer_track.id
    end
  end

  private

  def set_format
    request.format = 'html'
  end

end
