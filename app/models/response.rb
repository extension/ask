# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Response < ActiveRecord::Base
  include MarkupScrubber
  belongs_to :question
  belongs_to :resolver, :class_name => "User", :foreign_key => "resolver_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  has_many :ratings
  has_many :images, :as => :assetable, :class_name => "Response::Image", :dependent => :destroy
  belongs_to :contributing_question, :class_name => "Question", :foreign_key => "contributing_question_id"
  
  accepts_nested_attributes_for :images, :allow_destroy => true
  
  before_save :set_public_flag
  after_create :set_timings
  after_save :check_first_response, :index_parent_question
  
  validates :body, :presence => true
  validate :validate_attachments

  scope :latest, order('created_at DESC')
  scope :expert, where(is_expert: true)
  scope :expert_after_public, where(is_expert: true).where(previous_expert: false)
  scope :non_expert, where(is_expert: false)

  def validate_attachments
    allowable_types = ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png']
    images.each {|i| self.errors[:base] << "Image is over 5MB" if i.attachment_file_size > 5.megabytes}
    images.each {|i| self.errors[:base] << "Image is not correct file type (.jpg, .png, or .gif allowed)" if !allowable_types.include?(i.attachment_content_type)}
  end

  # attr_writer override for body to scrub html
  def body=(bodycontent)
    write_attribute(:body, self.cleanup_html(bodycontent))
  end
  
  class Response::Image < Asset
    has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  end

  def set_timings
    question_submitted_at = self.question.created_at
    update_attribs = {}
    update_attribs[:time_since_submission] = (self.created_at - question_submitted_at)

    if(last_response = self.question.responses.where('id != ?',self.id).where('created_at <= ?',self.created_at).latest.first)
      update_attribs[:time_since_last] = (self.created_at - last_response.created_at)
      update_attribs[:previous_expert] = last_response.is_expert?    
    else
      # first response - set time_since_last to time_since_submission and previous_expert false to ease calculations
      update_attribs[:time_since_last] = (self.created_at - question_submitted_at)
      update_attribs[:previous_expert] = false
    end         
    self.update_attributes(update_attribs)
  end

  private

  def set_public_flag
    if(self.resolver_id.blank?)
      self.is_expert = false
    else
      self.is_expert = true
    end
  end

  def check_first_response
    if(self.question.initial_response_id.blank?)
      self.question.update_attributes({initial_response_id: self.id, initial_response_time: self.created_at - self.question.created_at})
    end
  end
  
  def index_parent_question
    Sunspot.index(self.question)
  end
    
end

