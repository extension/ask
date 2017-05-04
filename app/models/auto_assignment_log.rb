# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AutoAssignmentLog < ActiveRecord::Base
  serialize :user_pool
  belongs_to :question
  belongs_to :assignee, :foreign_key => "assignee_id", :class_name => "User"
  belongs_to :group
  belongs_to :question_location, :foreign_key => "question_location_id", :class_name => "Location"
  belongs_to :question_county, :foreign_key => "question_county_id", :class_name => "County"



  # auto assignment constants
  LOCATION_MATCH_GROUP_IGNORES_COUNTY = 101
  COUNTY_MATCH = 102
  LOCATION_MATCH_ANY_COUNTY = 103
  ANYWHERE = 104
  LEADER = 105
  WRANGLER_HANDOFF_OUTSIDE_LOCATION = 201
  WRANGLER_HANDOFF_EMPTY_GROUP = 202
  WRANGLER_HANDOFF_NO_MATCHES = 203
  WRANGLER_HANDOFF_MANUAL = 204
  WRANGLER_HANDOFF_NO_LEADERS = 205
  WRANGLER_COUNTY_MATCH = 210
  WRANGLER_LOCATION_MATCH = 211
  WRANGLER_ANYWHERE = 212

  REJECTION_EMPTY_GROUP = 302
  REJECTION_NO_MATCHES = 303

  # doh!
  FAILURE = 13

  def self.code_to_constant_string(code)
    constantslist = self.constants
    constantslist.each do |c|
      value = self.const_get(c)
      if(value.is_a?(Fixnum) and code == value)
        return c.to_s.downcase
      end
    end

    # if we got here?  return nil
    return nil
  end

  def auto_assignment_reason
    case assignment_code
    when LOCATION_MATCH_GROUP_IGNORES_COUNTY
      "The question location (#{self.question_location.name}) matched the your expertise location. Note: This group ignores counties when automatically assigning questions."
    when COUNTY_MATCH
      "You chose to accept questions based on county and location (#{self.question_county.name}, #{self.question_location.name})."
    when LOCATION_MATCH_ANY_COUNTY
      "You chose to accept questions based on location (any county in #{self.question_location.name})."
    when ANYWHERE
      "You chose to accept questions from any location, and no specific location matched for this question."
    when LEADER
      "You are a group leader, and no other group members were available that accept automatic assignments"
    when WRANGLER_COUNTY_MATCH
      wrangler_assignment_reason + " You are a question wrangler matching the question county and location (#{self.question_county.name}, #{self.question_location.name})."
    when WRANGLER_LOCATION_MATCH
      wrangler_assignment_reason + " You are a question wrangler matching the question location (#{self.question_location.name})."
    when WRANGLER_ANYWHERE
      wrangler_assignment_reason + " You are a question wrangler accepting questions from any location and no specific location matched for this question."
    when FAILURE
      "Unable to find an automatic assignee for this question"
    else
      ''
    end
  end

  def wrangler_assignment_reason
    case wrangler_assignment_code
    when WRANGLER_HANDOFF_EMPTY_GROUP
      "No present assignees were available in #{self.group.name}."
    when WRANGLER_HANDOFF_NO_MATCHES
      "No assignee matches were found in #{self.group.name}."
    when WRANGLER_HANDOFF_MANUAL
      "Previous assigneed handed off to a question wrangler."
    when WRANGLER_HANDOFF_NO_LEADERS
      "No group leaders were found in #{self.group.name}"
    else
      ""
    end
  end



  def self.log_assignment(log_values)
    question = log_values[:question]
    group = log_values[:group]
    user_pool = log_values[:user_pool]
    if(!user_pool.nil?)
      pool_floor = user_pool.values.map{|h| h[:open_question_count]}.min
    end

    self.create(question: question,
                question_location_id: question.location_id,
                question_county_id: question.county_id,
                assignee: log_values[:assignee],
                group: log_values[:group],
                group_member_count: group.joined.count,
                group_present_count: group.joined.not_away.count,
                pool_floor: pool_floor,
                assignment_code: log_values[:assignment_code],
                wrangler_assignment_code: log_values[:wrangler_assignment_code],
                assignee_tests: log_values[:assignee_tests],
                user_pool: user_pool )
  end

  def self.mapped_user_pool(user_pool)
    Hash[user_pool.map{|u| [u.id, {open_question_count: u.open_question_count, last_question_assigned_at: u.last_question_assigned_at, routing_instructions: u.routing_instructions, auto_route: u.auto_route}]}]
  end

end
