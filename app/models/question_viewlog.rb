# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class QuestionViewlog < ActiveRecord::Base
  belongs_to :user
  belongs_to :question
  has_many :activity_logs, :as => :loggable, dependent: :destroy
  validates :user, :presence => true
  
  VIEW = 1

  ACTIVITY_MAP = {
    1   => "viewed",
  }
  scope :views, where(activity: 1)
  
  # don't recommend making this a callback, instead
  # intentionally call it where appropriate (like questionActivity.create_or_update)
  def create_activity_log(additional_information)
    self.activity_logs.create(user: self.user, additional: additional_information)
  end
  
  def description
    ACTIVITY_MAP[self.activity]
  end
  
  def self.description_for_id(id_number)
    ACTIVITY_MAP[id_number]
  end
      
  def self.log_view(user,question,source = nil)
    activity = VIEW
    self.create_or_update(user: user, question: question, activity: activity)
  end
  

  def self.find_by_unique_key(attributes)
    scoped = self.where(user_id: attributes[:user].id)
    scoped = scoped.where(question_id: attributes[:question].id)
    scoped.first
  end
  
  def self.create_or_update(attributes,additional_information = nil)
    begin 
      record = self.create(attributes)
    rescue ActiveRecord::RecordNotUnique => e
      record = self.find_by_unique_key(attributes)
      record.increment!(:view_count)
    end
    record.create_activity_log(additional_information)  
  end
  
end
