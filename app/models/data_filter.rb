# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class DataFilter < ActiveRecord::Base
  serialize :settings
  serialize :notifylist
  attr_accessible :creator, :created_by, :settings, :notifylist
  attr_accessible :dump_last_filesize, :dump_last_generated_at, :dump_last_runtime, :dump_in_progress

  ALL = 1
  KNOWN_KEYS = ['locations','responder_locations','groups','tags','date_range']

  before_save :set_fingerprint
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"

  def self.find_or_create_by_settings(settings,creator)
    settings_array = self.convert_settings_hash(settings)
    return find(ALL) if settings_array.blank?
    find_fingerprint = self.settings_fingerprint(settings_array)
    if(!(browse_filter = self.find_by_fingerprint(find_fingerprint)))
      browse_filter = self.create(settings: settings, creator: creator)
    end
    browse_filter
  end

  def queue_filedump
    if(!Settings.redis_enabled)
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


  def is_all?
    (self.id == 1)
  end

  def settings
    Hash[read_attribute(:settings)]
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

  def settings_to_objects
    objecthash = {}
    self.settings.each do |filter_key,id_list|
      case filter_key
      when 'locations'
        objecthash[filter_key] = Location.where("id in (#{id_list.join(',')})").order(:name).all
      when 'responder_locations'
        objecthash[filter_key] = Location.where("id in (#{id_list.join(',')})").order(:name).all
      end
    end
    objecthash
  end

  # settings_hash is expected to be what comes from the form POST
  # e.g. a hash of key => comma delimited string of id's
  def settings=(settings_hash)
    savesettings = self.class.convert_settings_hash(settings_hash)
    if(savesettings)
      write_attribute(:settings, savesettings)
    end
  end

  def filename
    now = Time.now.utc
    "#{Rails.root}/#{Settings.downloads_data_dir}/colleagues_filtered_by_#{self.id.to_s}_#{now.strftime("%Y-%m-%d")}.csv"
  end

  def dump_count
    Person.display_accounts.filtered_by(self).count
  end

  # def dump_to_file(forceupdate=false)
  #   return nil if(self.dump_in_progress? and !forceupdate)
  #   this_filename = self.filename
  #   if(!self.dumpfile_updated? or forceupdate)
  #     self.update_attributes(dump_in_progress: true)
  #     benchmark = Benchmark.measure do
  #       # todo: something other than display accounts?
  #       Person.display_accounts.filtered_by(self).dump_to_csv(this_filename,{browse_filter: self})
  #     end
  #     Notification.create(:notification_type => Notification::COLLEAGUE_DOWNLOAD_AVAILABLE, :notifiable => self)
  #     self.update_attributes(dump_last_generated_at: Time.now, dump_last_runtime: benchmark.real, dump_last_filesize: File.size(this_filename), dump_in_progress: false)
  #   end
  #   this_filename
  # end

  def dumpfile_updated?
    File.exists?(self.filename)
  end

  def available_for_download?
    self.dumpfile_updated? and !self.dump_in_progress?
  end

  def self.convert_settings_hash(settings_hash)
    savesettings = []
    KNOWN_KEYS.each do |key|
      if(!settings_hash[key].blank?)
        savesettings << [key,settings_hash[key].split(',').map{|i| i.strip.to_i}.sort]
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
