# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class DemographicQuestion < ActiveRecord::Base
  ## includes
  include CacheTools
  extend YearWeek

  ## attributes
  attr_accessible :creator, :creator_id, :prompt, :responses, :responsetype, :questionorder
  serialize :responses

  ## constants
  MULTIPLE_CHOICE = 'multiple_choice'

  ## associations
  belongs_to :creator, :class_name => "User"
  has_many :demographics
  has_many :users, through: :demographics

  ## scopes
  scope :active, where(is_active: true)

  ## validations
  ## filters
  ## class methods
  def self.mean_response_rate
    response_rate = {}
    limit_pool = Question.public_submissions.demographic_eligible.pluck(:submitter_id).uniq
    response_rate[:eligible] = limit_pool.size
    limit_list = self.active.pluck(:id)
    response_rate[:responses] = (Demographic.where("user_id in (#{limit_pool.join(',')})").where("demographic_question_id IN (#{limit_list.join(',')})").count / limit_list.size)
    response_rate
  end

  ## instance methods

  def answer_for_user(user)
    self.demographics.where(user_id: user.id).first
  end

  def response_value(response)
    if(self.responselist.include?(response))
      self.responselist.index(response) + 1
    else
      0
    end
  end

  def responselist
    self.responses
  end

  def create_or_update_answers(options = {})
    user = options[:user]
    params = options[:params]

    case self.responsetype
    when MULTIPLE_CHOICE
      if(answer = self.answer_for_user(user))
        answer.update_attributes({response: params[:response], value: self.response_value(params[:response])})
      else
        answer = self.demographics.create(user: user, response: params[:response], value: self.response_value(params[:response]))
      end
      answer
    else
      # nothing
    end
  end

  def response_data(cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__)
      Rails.cache.fetch(cache_key,cache_options) do
        _response_data
      end
    else
      _response_data
    end
  end

  def _response_data
    data = {}
    limit_to_pool = Question.public_submissions.demographic_eligible.pluck(:submitter_id).uniq
    data[:eligible] = limit_to_pool.size
    response_counts = self.demographics.where("demographics.user_id IN (#{limit_to_pool.join(',')})").group('LOWER(response)').count
    data[:responses] = response_counts.values.sum
    data[:labels] = self.responses
    data[:counts] = []
    self.responses.each do |r|
      data[:counts] << ((response_counts[r.downcase].blank?) ? 0 : response_counts[r.downcase])
    end
    data
  end

end
