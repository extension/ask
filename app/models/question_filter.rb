# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class QuestionFilter < ActiveRecord::Base
  serialize :settings
  attr_accessible :creator, :created_by, :settings, :use_count

  KNOWN_KEYS = ['question_locations','question_counties','assigned_groups','tags','date_range']

  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  before_save :set_fingerprint

  def self.find_or_create_by_settings(settings,creator)
    settings_array = self.convert_settings_hash(settings)
    return nil if settings_array.blank?
    find_fingerprint = self.settings_fingerprint(settings_array)
    if(!(question_filter = self.find_by_fingerprint(find_fingerprint)))
      question_filter = self.create(settings: settings, creator: creator)
    end
    question_filter
  end


  def settings_to_objects
    objecthash = {}
    self.settings.each do |filter_key,id_list|
      case filter_key
      when 'tags'
        objecthash[filter_key] = Tag.where("id in (#{id_list.join(',')})").order(:name).all
      when 'assigned_groups'
        objecthash[filter_key] = Group.where("id in (#{id_list.join(',')})").order(:name).all
      when 'question_locations'
        objecthash[filter_key] = Location.where("id in (#{id_list.join(',')})").order(:name).all
      when 'question_counties'
        objecthash[filter_key] = County.where("id in (#{id_list.join(',')})").order(:name).all
      end
    end
    objecthash
  end

  def settings
    Hash[read_attribute(:settings)]
  end


  # settings_hash is expected to be what comes from the form POST
  # e.g. a hash of key => comma delimited string of id's
  def settings=(settings_hash)
    savesettings = self.class.convert_settings_hash(settings_hash)
    if(savesettings)
      write_attribute(:settings, savesettings)
    end
  end

  def self.convert_settings_hash(settings_hash)
    savesettings = []
    KNOWN_KEYS.each do |key|
      if(!settings_hash[key].blank?)
        if(key == 'date_range')
          #TODO  something for date range
        else
          # assumes array of objects
          savesettings << [key,settings_hash[key].split(',').map{|i| i.strip.to_i}.sort]
        end
      end
    end
    savesettings
  end

  def self.settings_fingerprint(settings)
    Digest::SHA1.hexdigest(settings.to_yaml)
  end

  def set_fingerprint
    self.fingerprint = self.class.settings_fingerprint(read_attribute(:settings))
  end


end
