# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class EvaluationQuestion < ActiveRecord::Base
  attr_accessible :prompt, :secondary_prompt, :responses, :responsetype, :range_start, :range_end, :questionorder
  serialize :responses

  # types, strings in case we ever want to inherit from this model
  MULTIPLE_CHOICE = 'multiple_choice'
  SCALE = 'scale'
  OPEN = 'open'
  OPEN_DOLLAR_VALUE = 'open_dollar_value'
  OPEN_TIME_VALUE = 'open_time_value'
  TEXT = 'text'

  has_many :evaluation_answers

  scope :active, where(is_active: true)


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
      response.gsub(%r{[^\d\.]},'').to_i
    when OPEN_TIME_VALUE
      # interpret as days
      response.gsub(%r{[^\d]},'').to_i
    else 
      0
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

end