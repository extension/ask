# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class DemographicQuestion < ActiveRecord::Base
  serialize :responses
  belongs_to :creator, :class_name => "User"
  attr_accessible :creator, :creator_id, :prompt, :responses, :responsetype, :questionorder
  has_many :demographics
  has_many :users, through: :demographics

  MULTIPLE_CHOICE = 'multiple_choice'

  scope :active, where(is_active: true)

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

end