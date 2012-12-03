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
  after_create :schedule_activity_notification
  
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
    write_attribute(:content, self.cleanup_html(comment_content))
  end
  
  def schedule_activity_notification
#    if !Notification.pending_activity_notification?(self.question)
#      Notification.create(notifiable: self.event, notificationtype: Notification::ACTIVITY, delivery_time: Notification::ACTIVITY_NOTIFICATION_INTERVAL.from_now)
#    end
#    if self.is_reply?
#      Notification.create(notifiable: self, notificationtype: Notification::COMMENT_REPLY, delivery_time: 1.minute.from_now) unless self.learner == self.parent.learner
    end
end
