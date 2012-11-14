# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Comment < ActiveRecord::Base
  include MarkupScrubber

  belongs_to :question
  belongs_to :user
  has_many :ratings
  
  # make sure to keep this callback ahead of has_ancestry, which has its own callbacks for destroy
  before_destroy :set_orphan_flag_on_children
  
  # using the ancestry gem for threaded comments
  # orphan strategy will move the parent's children up a level in the hierarchy if the parent gets deleted
  has_ancestry :orphan_strategy => :rootify
  
  validates :content, :user_id, :question_id, :presence => true
  
  def created_by_blocked_user?
    return true if self.user.is_blocked
    return false
  end
  
  def set_orphan_flag_on_children
    self.children.update_all(parent_removed: true)
  end
  
  # attr_writer override for content to scrub html
  def content=(comment_content)
    write_attribute(:content, self.scrub_and_sanitize(comment_content))
  end
end
