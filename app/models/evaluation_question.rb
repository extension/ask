# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class EvaluationQuestion < ActiveRecord::Base
  ## includes
  include CacheTools
  extend YearWeek

  ## attributes
  attr_accessible :prompt, :secondary_prompt, :responses, :responsetype, :range_start, :range_end, :questionorder
  serialize :responses

  ## constants
  # types, strings in case we ever want to inherit from this model
  MULTIPLE_CHOICE = 'multiple_choice'
  SCALE = 'scale'
  OPEN = 'open'
  OPEN_DOLLAR_VALUE = 'open_dollar_value'
  OPEN_TIME_VALUE = 'open_time_value'
  TEXT = 'text'

  ## associations
  has_many :evaluation_answers

  ## scopes
  scope :active, where(is_active: true)

  ## class methods

  def self.mean_response_rate
    response_rate = {}
    limit_pool = Question.public_submissions.evaluation_eligible.pluck(:id).uniq
    response_rate[:eligible] = limit_pool.size
    limit_list = self.active.pluck(:id)
    response_rate[:responses] = (EvaluationAnswer.where("question_id IN (#{limit_pool.join(',')})").where("evaluation_question_id IN (#{limit_list.join(',')})").count / limit_list.size)
    response_rate
  end

  def self.weekly_mean_response_rate
    weeks = {}
    earliest_date = Question.public_submissions.evaluation_eligible.minimum(:initial_response_at).to_date
    latest_date = Date.today
    year_weeks = self.year_weeks_between_dates(earliest_date,latest_date)
    year_weeks.each do |year,week|
      yearweek = self.yearweek(year,week)
      response_rate = {}
      limit_pool = Question.public_submissions.evaluation_eligible.where("YEARWEEK(initial_response_at) = #{yearweek}").pluck(:id).uniq
      response_rate[:eligible] = limit_pool.size
      if(limit_pool.size > 0)
        limit_list = self.active.pluck(:id)
        response_rate[:responses] = (EvaluationAnswer.where("question_id IN (#{limit_pool.join(',')})").where("evaluation_question_id IN (#{limit_list.join(',')})").count / limit_list.size)
      else
        response_rate[:responses] = 0
      end
      weeks[yearweek] = response_rate
    end
    weeks
  end

  ## instance methods

  def answer_for_user_and_question(user,question)
    self.evaluation_answers.where(user_id: user.id).where(question_id: question.id).first
  end

  def answer_value_for_user_and_question(user,question)
    return nil if(question.nil? or user.nil?)
    if(answer = self.evaluation_answers.where(user_id: user.id).where(question_id: question.id).first)
      case self.responsetype
      when MULTIPLE_CHOICE
        answer.value
      when SCALE
        answer.value
      else
        answer.response
      end
    else
      nil
    end
  end

  def answer_counts_for_question(question)
    self.evaluation_answers.where(question_id: question.id).group(:response).count
  end

  def answer_total_for_question(question)
    self.evaluation_answers.where(question_id: question.id).count
  end

  def answer_counts
    self.evaluation_answers.group(:response).count
  end

  def answer_total
    self.evaluation_answers.count
  end

  def response_value(response)
    case self.responsetype
    when MULTIPLE_CHOICE
      self.responses.index(response)
    when SCALE
      response.to_i
    when OPEN_DOLLAR_VALUE
      # use the mean of all the numbers we find
      all_numerics = response.scan(%r{[\d\.,]+}).map{|i| i.tr(',','').to_i}
      if(all_numerics.size >= 1)
        all_numerics.mean.to_i
      else
        nil
      end
    when OPEN_TIME_VALUE
      # interpret as days
      response.gsub(%r{[^\d]},'').to_i
    else
      ''
    end
  end

  def reporting_response_value(response)
    case self.responsetype
    when MULTIPLE_CHOICE
      self.response_value(response) + 1
    else
      self.response_value(response)
    end
  end

  def create_or_update_answers(options = {})
    user = options[:user]
    question = options[:question]
    params = options[:params]

    begin
      answer = self.evaluation_answers.create(user: user, question: question, response: params[:response], value: self.response_value(params[:response]))
    rescue ActiveRecord::RecordNotUnique => e
      if(answer = self.answer_for_user_and_question(user,question))
        answer.update_attributes({response: params[:response], value: self.response_value(params[:response])})
      end
    end
    answer
  end

  def response_data(response_data_options = {}, cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,response_data_options)
      Rails.cache.fetch(cache_key,cache_options) do
        _response_data(response_data_options)
      end
    else
      _response_data(response_data_options)
    end
  end

  def _response_data(response_data_options = {})
    question_filter = response_data_options[:question_filter]
    public_only = response_data_options[:show_all].present? ? !response_data_options[:show_all] : true
    data = {}
    limit_scope = Question.evaluation_eligible

    if(question_filter.present?)
      limit_scope = limit_scope.filtered_by(question_filter)
    end

    if(public_only)
      limit_scope = limit_scope.public_submissions
    end

    limit_to_pool = limit_scope.pluck(:id).uniq

    data[:eligible] = limit_to_pool.size
    case self.responsetype
    when MULTIPLE_CHOICE
      response_counts = self.evaluation_answers.where("evaluation_answers.question_id IN (#{limit_to_pool.join(',')})").group('LOWER(response)').count
      data[:responses] = response_counts.values.sum
      data[:labels] = self.responses.map{|r| r.truncate(25)}
      data[:counts] = []
      self.responses.each do |r|
        data[:counts] << ((response_counts[r.downcase].blank?) ? 0 : response_counts[r.downcase])
      end
    when SCALE
      response_counts = self.evaluation_answers.where("evaluation_answers.question_id IN (#{limit_to_pool.join(',')})").group('value').count
      data[:responses] = response_counts.values.sum
      data[:labels] = (self.range_start..self.range_end).to_a
      data[:counts] = []
      (self.range_start..self.range_end).to_a.each do |value|
        data[:counts] << ((response_counts[value].blank?) ? 0 : response_counts[value])
      end
    when OPEN_DOLLAR_VALUE
      values = self.evaluation_answers.where("evaluation_answers.question_id IN (#{limit_to_pool.join(',')})").pluck('value').compact
      data[:responses] = values.size
      data[:labels] = ['$0-$249','$250-$499','$500-$999','$1,000 - $2,499','$2,500 - $4,999','$5,000 - $9,999','>= $10,000']
      value_bins = {}
      data[:labels].each do |l|
        value_bins[l] = 0
      end
      values.each do |value|
        case value
        when 0..249
          value_bins['$0-$249'] +=1
        when 250..499
          value_bins['$250-$499'] +=1
        when 500..999
          value_bins['$500-$999'] +=1
        when 1000..2499
          value_bins['$1,000 - $2,499'] +=1
        when 2500..4999
          value_bins['$2,500 - $4,999'] +=1
        when 5000..9999
          value_bins['$5,000 - $9,999'] +=1
        else
          value_bins['>= $10,000'] +=1
        end
      end
      data[:counts] = []
      data[:labels].each do |l|
        data[:counts] << ((value_bins[l].blank?) ? 0 : value_bins[l])
      end
    else
      return nil
    end
    data
  end

end
