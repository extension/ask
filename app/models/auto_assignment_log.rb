# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AutoAssignmentLog < ActiveRecord::Base
  serialize :pool
  belongs_to :question
  belongs_to :user
  belongs_to :group

  def self.log_assignment(log_values)
    user_pool = log_values[:user_pool].sort { |a, b| a.open_question_count <=> b.open_question_count }
    pool_floor = user_pool[0].open_question_count
    saved_pool = Hash[user_pool.map{|u| [u.id, {open_question_count: u.open_question_count, last_question_assigned_at: u.last_question_assigned_at}]}]
    self.create(question: log_values[:question], user: log_values[:user], group: log_values[:group], pool_floor: pool_floor, reason: log_values[:reason], pool: saved_pool )
  end

end
