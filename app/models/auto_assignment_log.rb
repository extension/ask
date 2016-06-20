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


  # auto assignment constants
  LOCATION_MATCH_GROUP_IGNORES_COUNTY = 101
  # reason_assigned = "The question location (#{self.location.name}) matched the member's expertise location. Note: This group ignores counties when automatically assigning questions."
  COUNTY_MATCH = 102
  # reason_assigned = "You chose to accept questions based on location (#{self.county.name})"
  LOCATION_MATCH_ALL_COUNTY = 103
  # reason_assigned = "You chose to accept questions based on location (all counties in #{self.location.name})"
  ANYWHERE = 104
  # reason_assigned = "You chose to accept questions from #{group.name} group"
  LEADER = 105
  # reason_assigned = "You are a group leader"
  WRANGLER_HANDOFF_OUTSIDE_LOCATION = 201
  WRANGLER_HANDOFF_EMPTY_GROUP = 202
  WRANGLER_HANDOFF_NO_MATCHES = 203

  WRANGLER_COUNTY_MATCH = 210
  WRANGLER_LOCATION_MATCH = 211
  WRANGLER_ANYWHERE = 212

  # doh!
  FAILURE = 13


  def self.log_assignment(log_values)
    user_pool = log_values[:user_pool].sort { |a, b| a.open_question_count <=> b.open_question_count }
    pool_floor = user_pool[0].open_question_count
    self.create(question: log_values[:question], user: log_values[:user], group: log_values[:group], pool_floor: pool_floor, reason: log_values[:reason], pool: saved_pool )
  end

  def self.mapped_user_pool(user_pool)
    Hash[user_pool.map{|u| [u.id, {open_question_count: u.open_question_count, last_question_assigned_at: u.last_question_assigned_at, routing_instructions: u.routing_instructions, auto_route: u.auto_route}]}]
  end

end
