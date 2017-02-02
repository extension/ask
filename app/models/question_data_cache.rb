# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class QuestionDataCache < ActiveRecord::Base
  serialize :data_values
  attr_accessible :question_id, :data_values, :question, :version

  CURRENT_VERSION = 3

  belongs_to :question

  def self.rebuild_all
    Question.find_in_batches do |question_group|
      question_group.each do |question|
        question.update_data_cache
      end # question
    end # question group
  end


  def self.create_or_update_from_question(question)
    data = []
    data << question.id
    data << question.is_private
    data << (!question.user_ip.blank?)
    data << question.class.name_or_nil(question.detected_location)
    data << ((question.detected_location.nil?) ? nil : question.detected_location.fips)
    data << question.class.name_or_nil(question.detected_county)
    data << ((question.detected_county.nil?) ? nil : question.detected_county.fips)
    data << question.class.name_or_nil(question.location)
    data << ((question.location.nil?) ? nil : question.location.fips)
    data << (question.location_id == question.original_location_id)
    data << question.class.name_or_nil(question.county)
    data << ((question.county.nil?) ? nil : question.county.fips)
    data << (question.county_id == question.original_county_id)
    data << question.original_group_id
    data << question.class.name_or_nil(question.original_group)
    data << question.assigned_group_id
    data << question.class.name_or_nil(question.assigned_group)
    data << question.status
    data << question.is_mobile?
    data << question.created_at.utc.strftime("%Y-%m-%d %H:%M:%S")
    data << question.submitter_id
    data << question.submitter_is_extension?
    data << question.aae_version
    data << question.source_to_s
    data << question.responses.non_expert.count
    data << question.responses.expert.count
    data << question.responses.expert.count('distinct(resolver_id)')
    if(responder = question.initial_responder)
      data << question.initial_response_at.utc.strftime("%Y-%m-%d %H:%M:%S")
      data << responder.id
      data << responder.name
      data << question.class.name_or_nil(responder.location)
      data << ((responder.location.nil?) ? nil : responder.location.fips)
      data << question.class.name_or_nil(responder.county)
      data << ((responder.county.nil?) ? nil : responder.county.fips)
      data << (question.initial_response_time / 3600).to_f
      data << (question.mean_response_time / 3600).to_f
      data << (question.median_response_time / 3600).to_f
    else
      data << nil # response_at
      data << nil # id
      data << nil # name
      data << nil # location
      data << nil # location_fips
      data << nil # county
      data << nil # county_fips
      data << nil # response_time
      data << nil # mean
      data << nil # median
    end
    data << question.demographic_eligible?
    data << question.evaluation_eligible?
    data << question.tags.map(&:name).join(',')
    # evaluation data
    eval_columns = []
    EvaluationQuestion.order(:id).active.each do |aeq|
      eval_columns << "evaluation_#{aeq.id}_response"
      eval_columns << "evaluation_#{aeq.id}_value"
    end
    eval_count = question.evaluation_answers.count
    if(eval_count > 0)
      data << eval_count
      question_data = {}
      question.evaluation_answers.each do |ea|
        question_data["evaluation_#{ea.evaluation_question_id}_response"] = ea.response
        question_data["evaluation_#{ea.evaluation_question_id}_value"] = ea.evaluation_question.reporting_response_value(ea.response)
      end

      eval_columns.each do |column|
        value = question_data[column]
        if(value.is_a?(Time))
          data << value.strftime("%Y-%m-%d %H:%M:%S")
        else
          data << value
        end
      end
    else
      data << 0
      eval_columns.each do |column|
        data << nil
      end
    end

    if(qdc = self.where(question_id: question.id).first)
      qdc.update_attributes({data_values: data, version: CURRENT_VERSION})
    else
      qdc = self.create(question_id: question.id, data_values: data, version: CURRENT_VERSION)
    end

    qdc
  end







end
