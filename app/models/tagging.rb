class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true

  validates :tag_id, :uniqueness => {:scope => [:taggable_id, :taggable_type]}

  def self.change_tag(current_tag_id, replacement_tag_id)
    self.where(:tag_id => current_tag_id).update_all(tag_id: replacement_tag_id)
  end
end
