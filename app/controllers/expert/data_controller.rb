# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Expert::DataController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid

  def index
    if(params[:forcecacheupdate])
      options = {force: true}
    else
      options = {}
    end
    @question_stats = Question.not_rejected.answered_stats_by_yearweek('questions',options)
    @expert_stats = QuestionEvent.stats_by_yearweek(options)
    @responsetime_stats = Question.not_rejected.answered_stats_by_yearweek('responsetime',options)
    @evaluation_response_rate = EvaluationQuestion.mean_response_rate
    @demographic_response_rate = DemographicQuestion.mean_response_rate
  end



  def demographics
    @demographic_questions = DemographicQuestion.order(:questionorder).active
  end

  def demographics_download
    @download = Download.find_by_label('demographics')
    @response_rate = DemographicQuestion.mean_response_rate
  end

  def evaluations
    @showform = (params[:showform] and TRUE_VALUES.include?(params[:showform]))

    if(params[:filter] && @question_filter = QuestionFilter.find_by_id(params[:filter]))
      @question_filter_objects = @question_filter.settings_to_objects
    end

    @show_all = (params[:show_all] and TRUE_VALUES.include?(params[:show_all]))

    @evaluation_questions = EvaluationQuestion.order(:questionorder).active
  end

  def questions
    @showform = (params[:showform] and TRUE_VALUES.include?(params[:showform]))

    if(params[:filter] && @question_filter = QuestionFilter.find_by_id(params[:filter]))
      @question_filter_objects = @question_filter.settings_to_objects
      @questions = Question.not_rejected.filtered_by(@question_filter).order('questions.created_at DESC').page(params[:page])
    else
      @questions = Question.not_rejected.order('questions.created_at DESC').page(params[:page])
    end
  end

  def questions_download
    if(params[:filter] && @question_filter = QuestionFilter.find_by_id(params[:filter]))
      @questions_filter_id = @question_filter.id
      @question_filter_objects = @question_filter.settings_to_objects
      @download = Download.find_or_create_by_label_and_filter('questions',@question_filter)
    else
      @download = Download.find_or_create_by_label_and_filter('questions')
    end
  end


  def getfile
    @download = Download.find(params[:id])
    if(@download.dump_in_progress?)
      flash[:notice] = 'This export is currently in progress. Check back in a few minutes.'
      @download.add_to_notifylist(current_user)
      if(@download.label == 'demographics')
        return redirect_to(expert_data_demographics_download_url)
      elsif(@download.label == 'questions')
        if(!@download.filter_id.nil? and filter = QuestionFilter.find_by_id(@download.filter_id))
          return redirect_to(expert_data_questions_download_url(filter: filter.id))
        else
          return redirect_to(expert_data_questions_download_url)
        end
      else
        return redirect_to(expert_data _url)
      end
    elsif(!@download.dumpfile_updated?)
      @download.queue_filedump
      @download.add_to_notifylist(current_user)
      flash[:notice] = 'This export has not been updated. Check back in a few minutes.'
      if(@download.label == 'demographics')
        return redirect_to(expert_data_demographics_download_url)
      elsif(@download.label == 'questions')
        if(!@download.filter_id.nil? and filter = QuestionFilter.find_by_id(@download.filter_id))
          return redirect_to(expert_data_questions_download_url(filter: filter.id))
        else
          return redirect_to(expert_data_questions_download_url)
        end
      else
        return redirect_to(expert_data _url)
      end
    else
      DownloadLog.create(download_id: @download.id, downloaded_by: current_user.id)
      send_file(@download.filename,
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=#{File.basename(@download.filename)}")
    end
  end

  def filter_questions
    if(question_filter = QuestionFilter.find_or_create_by_settings(params,current_user))
      return redirect_to(questions_expert_data_url(filter: question_filter.id))
    else
      return redirect_to(questions_expert_data_url)
    end
  end

  def filter_evaluations
    if(question_filter = QuestionFilter.find_or_create_by_settings(params,current_user))
      return redirect_to(evaluations_expert_data_url(filter: question_filter.id))
    else
      return redirect_to(evaluations_expert_data_url)
    end
  end



end
