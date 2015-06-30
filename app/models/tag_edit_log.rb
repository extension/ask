# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class TagEditLog < ActiveRecord::Base
  ## attributes
  attr_accessible :activitycode, :affected, :description, :user_id

  serialize :description
  serialize :affected

  ## activity codes
  TAG_DELETED                         = 1
  TAG_EDITED                          = 2

  # associations
  belongs_to :expert, :class_name => "User", :foreign_key => "user_id"

  def self.log_edited_tags(user, edit_hash)
    return self.log_tag_change(user, TAG_EDITED, edit_hash)
  end

  def self.log_deleted_tags(user, edit_hash)
    return self.log_tag_change(user, TAG_DELETED, edit_hash)
  end

  def self.log_tag_change(user, activity_code, edit_hash = nil)
    log_attributes = {}
    log_attributes[:user_id] = user.id
    log_attributes[:activitycode] = activity_code
    log_attributes[:description] = edit_hash

    return TagEditLog.create(log_attributes)
  end
end
