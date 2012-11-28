# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Preference < ActiveRecord::Base
  belongs_to :prefable, :polymorphic => true
  belongs_to :group
  belongs_to :question
  before_save :set_datatype
  before_save :set_classification_if_nil
  
  TRUE_PARAMETER_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES'].to_set
  FALSE_PARAMETER_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO'].to_set
  
  # convenience constants
  PREFERENCE_DEFAULTS = { 
   'notification.question.assigned_to_me' => true,
   'notification.question.incoming' => false,
   'notification.question.daily_summary' => false,
   'notification.question.comment' => false,
  }
  
  NOTIFICATION_ASSIGNED_TO_ME = 'notification.question.assigned_to_me'
  NOTIFICATION_INCOMING = 'notification.question.incoming'
  NOTIFICATION_DAILY_SUMMARY = 'notification.question.daily_summary'
  NOTIFICATION_COMMENT = 'notification.question.comment'
  
  def set_datatype
    if(self.value.nil?)
      self.datatype = nil
    elsif(self.value.class.name == 'TrueClass' or self.value.class.name == 'FalseClass')
      self.datatype = 'Boolean'
    else
      self.datatype = self.value.class.name
    end
  end
  
  def set_classification_if_nil
    if(self.classification.nil?)
      if(%r{(?<classificationname>\w+).(\w+)} =~ self.name)
        self.classification = classificationname
      end
    end
  end
  
  def value
    dbvalue = read_attribute(:value)
    if(!dbvalue.nil?)
      case self.datatype
      when 'Boolean'
        TRUE_PARAMETER_VALUES.include?(dbvalue)  
      when 'FixNum'
        dbvalue.to_i
      when 'String'
        dbvalue
      else 
        dbvalue
      end
    else
      nil
    end
  end      
  
  def self.setting(name,group_id=nil,question_id=nil)
    if(setting = where(name: name, group_id: group_id, question_id: question_id).first)
      setting.value
    else
      self.get_default(name)
    end
  end
  
  def self.settingsclassification(classification)
    where(classification: classification)
  end
  
  def self.get_default(name)
    if(!PREFERENCE_DEFAULTS[name].nil?)
      PREFERENCE_DEFAULTS[name]
    else
      nil
    end
  end
    
  def self.create_or_update(prefable,name,value,group_id=nil,question_id=nil)
    if(preference = where(prefable_id: prefable.id).where(prefable_type: prefable.class.name).where(name: name).where(group_id: group_id).first)
      preference.update_attribute(:value, value)
    else
      preference = self.create(prefable: prefable, name: name, value: value, group_id: group_id, question_id: question_id)
    end
    preference
  end

end
