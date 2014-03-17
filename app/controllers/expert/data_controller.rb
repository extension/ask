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
    @question_stats = Question.answered_stats_by_yearweek('questions',options)
    @expert_stats = QuestionEvent.stats_by_yearweek(options)
    @responsetime_stats = Question.answered_stats_by_yearweek('responsetime',options)
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
      @questions = Question.filtered_by(@question_filter).page(params[:page])
    else
      @questions = Question.page(params[:page])
    end
  end

  def questions_download
    if(params[:filter] && @question_filter = QuestionFilter.find_by_id(params[:filter]))
      @question_filter_objects = @question_filter.settings_to_objects
      @download = Download.find_or_create_by_label_and_filter('questions',@question_filter)
    else
      @download = Download.find_or_create_by_label_and_filter('questions')
    end
  end


  def getfile
    @download = Download.find(params[:id])


    if(@download.in_progress?)
      flash[:notice] = 'This export is currently in progress. Check back in a few minutes.'
      return redirect_to(downloads_url)
    elsif(!@download.updated?)
      @download.delay.dump_to_file
      flash[:notice] = 'This export has not been updated. Check back in a few minutes.'
      return redirect_to(downloads_url)
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
      flash[:warning] = 'Invalid filter provided.'
      return redirect_to(questions_expert_data_url)
    end
  end

  def filter_evaluations
    if(question_filter = QuestionFilter.find_or_create_by_settings(params,current_user))
      return redirect_to(evaluations_expert_data_url(filter: question_filter.id))
    else
      flash[:warning] = 'Invalid filter provided.'
      return redirect_to(evaluations_expert_data_url)
    end
  end



end
