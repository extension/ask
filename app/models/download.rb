# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Download < ActiveRecord::Base
  extend NilUtils

  serialize :notifylist
  attr_accessible :label, :last_filesize, :filterclass, :filter_id,
                  :last_generated_at, :last_runtime, :last_itemcount,
                  :display_label, :dump_in_progress, :notifylist


  # download "types"
  KNOWN_LABELS = ['questions','demographics']

  # kinda hacky and verbose
  def self.find_or_create_by_label_and_filter(label,filter=nil)
    if(!KNOWN_LABELS.include?(label))
      return nil
    end

    if(filter.nil?)
      if(dl = self.where(label: label).where(filter_id: nil).first)
        return dl
      elsif(label == 'questions')
        dl = Download.create(label: 'questions', display_label: 'Ask an Expert Questions')
        return dl
      else
        return nil
      end
    elsif(dl = self.where(label: label).where(filterclass: filter.class.name).where(filter_id: filter.id).first)
      return dl
    elsif(label == 'questions')
      dl = Download.create(label: 'questions', display_label: 'Ask an Expert Questions (Filtered)', filterclass: filter.class.name, filter_id: filter.id)
      return dl
    else
      return nil
    end
  end


  def queue_filedump
    if(!Settings.sidekiq_enabled)
      self.dump_to_file
    else
      self.class.delay_for(5.seconds).delayed_dump_to_file(self.id)
    end
  end

  def self.delayed_dump_to_file(record_id)
    if(record = find_by_id(record_id))
      record.dump_to_file
    end
  end


  def filename
    now = Time.now.utc
    filelabel = self.label
    if(!self.filter_id.nil? and !self.filterclass.nil?)
      filelabel += "_filtered_by_#{self.filterclass.downcase}_#{self.filter_id}"
    end
    "#{Rails.root}/#{Settings.downloads_data_dir}/#{filelabel}_#{now.strftime("%Y-%V")}.csv"
  end

  def dump_to_file(forceupdate=false)
    return nil if(self.dump_in_progress? and !forceupdate)
    this_filename = self.filename
    if(!self.dumpfile_updated? or forceupdate)
      self.update_attributes(dump_in_progress: true)
      last_itemcount = 0
      benchmark = Benchmark.measure do
        case self.label
        when 'questions'
          last_itemcount = self.dump_questions
        when 'demographics'
          last_itemcount = self.dump_demographics
        else
          last_itemcount = 0
        end
      end
      Notification.create(notifiable: self, notification_type: Notification::AAE_DATA_DOWNLOAD_AVAILABLE, created_by:1, recipient_id: 1, delivery_time: 1.minute.from_now)
      self.update_attributes(last_generated_at: Time.now,
                             last_runtime: benchmark.real,
                             last_filesize: File.size(this_filename),
                             dump_in_progress: false,
                             last_itemcount: last_itemcount)
    end
    this_filename
  end

  def dumpfile_updated?
    File.exists?(self.filename)
  end

  def available_for_download?
    self.dumpfile_updated? and !self.dump_in_progress?
  end

  def add_to_notifylist(person)
    list = self.notifylist || []
    if(!list.include?(person.id))
      list << person.id
      self.notifylist = list
      self.save
    end
    true
  end


  def dump_questions
    return if(label != 'questions')
    question_columns = [
      'question_id',
      'is_private',
      'detectable_location',
      'detected_location',
      'detected_location_fips',
      'detected_county',
      'detected_county_fips',
      'location',
      'location_fips',
      'location_changed',
      'county',
      'county_fips',
      'county_changed',
      'original_group_id',
      'original_group',
      'assigned_group_id',
      'assigned_group',
      'status',
      'submitted_from_mobile',
      'submitted_at',
      'submitter_id',
      'submitter_is_extension',
      'aae_version',
      'source',
      'submitter_response_count',
      'expert_response_count',
      'expert_responders',
      'initial_response_at',
      'initial_responder_id',
      'initial_responder_name',
      'initial_responder_location',
      'initial_responder_location_fips',
      'initial_responder_county',
      'initial_responder_county_fips',
      'initial_response_time',
      'mean_response_time',
      'median_response_time',
      'demographic_eligible',
      'evaluation_eligible',
      'tags'
    ]

    # evaluation data
    question_columns << 'evaluation_count'
    eval_columns = []
    EvaluationQuestion.order(:id).active.each do |aeq|
      eval_columns << "evaluation_#{aeq.id}_response"
      eval_columns << "evaluation_#{aeq.id}_value"
    end
    question_columns += eval_columns

    rowcount = 0
    CSV.open(self.filename,'wb') do |csv|
      headers = []
      question_columns.each do |column|
        headers << column
      end
      csv << headers
      question_scope = Question.not_rejected
      if(!self.filter_id.nil? and self.filterclass == 'QuestionFilter' and question_filter = QuestionFilter.find_by_id(self.filter_id))
        question_scope = question_scope.filtered_by(question_filter)
      end
        question_scope.find_in_batches do |question_group|
        question_group.each do |question|
          csv << question.data_cache
          rowcount += 1
        end # question
      end # question group
    end # csv
    rowcount
  end


  def dump_demographics
    return if(label != 'demographics')
    CSV.open(self.filename,'wb') do |csv|
      headers = []
      headers << 'submitter_is_extension'
      headers << 'demographics_count'
      demographic_columns = []
      DemographicQuestion.order(:id).active.each do |adq|
        demographic_columns << "demographic_#{adq.id}"
      end
      headers += demographic_columns
      csv << headers

      # data
      # evaluation_answer_questions
      eligible_submitters = Question.demographic_eligible.pluck(:submitter_id).uniq
      response_submitters = Demographic.pluck(:user_id).uniq
      eligible_response_submitters = eligible_submitters & response_submitters
      User.where("id in (#{eligible_response_submitters.join(',')})").order("RAND()").each do |person|
        demographic_count = person.demographics.count
        next if (demographic_count == 0)
        row = []
        row << person.has_exid?
        row << demographic_count
        demographic_data = {}
        person.demographics.each do |demographic_answer|
          demographic_data["demographic_#{demographic_answer.demographic_question_id}"] = demographic_answer.response
        end

        demographic_columns.each do |column|
          row << demographic_data[column]
        end

        csv << row
      end
    end
  end




end
