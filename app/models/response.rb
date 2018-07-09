# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Response < ActiveRecord::Base
  # subclasses
  class Response::Image < Asset
    has_attached_file :attachment,
                      :url => "/uploads/:class/:attachment/:id_partition/:basename_:style.:extension",
                      :styles => Proc.new { |attachment| attachment.instance.styles }
                        attr_accessible :attachment

    # http://www.ryanalynporter.com/2012/06/07/resizing-thumbnails-on-demand-with-paperclip-and-rails/
    def dynamic_style_format_symbol
      URI.escape(@dynamic_style_format).to_sym
    end

    def styles
      unless @dynamic_style_format.blank?
        { dynamic_style_format_symbol => @dynamic_style_format }
      else
        { :original => resize, :medium => "300x300>", :thumb => "100x100>" }
      end
    end

    def dynamic_attachment_url(format)
      @dynamic_style_format = format
      attachment.reprocess!(dynamic_style_format_symbol) unless attachment.exists?(dynamic_style_format_symbol)
      attachment.url(dynamic_style_format_symbol)
    end

    def resize
      # resize all images to a reasonable file size and so paperclip can fix orientation
      "4800x4800>"
    end
  end

  # includes
  include MarkupScrubber

  # attributes
  has_paper_trail :on => [:update], :only => [:body]

  # constants
  YEARWEEK_RESOLVED = 'YEARWEEK(responses.created_at,3)'

  # associations
  belongs_to :question
  belongs_to :resolver, :class_name => "User", :foreign_key => "resolver_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  has_many :images, :as => :assetable, :class_name => "Response::Image", :dependent => :destroy
  accepts_nested_attributes_for :images, :allow_destroy => true

  # scopes
  scope :latest, order('created_at DESC')
  scope :expert, where(is_expert: true)
  scope :expert_after_public, where(is_expert: true).where(previous_expert: false)
  scope :non_expert, where(is_expert: false)

  # validations
  validates :body, :presence => true
  validate :validate_attachments

  # filters
  before_save :set_public_flag
  after_create :set_timings
  after_save :check_first_response, :index_parent_question, :update_question_data

  def validate_attachments
    allowable_types = ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png']
    images.each {|i| self.errors[:base] << "Image is not correct file type (.jpg, .png, or .gif allowed)" if !allowable_types.include?(i.attachment_content_type)}
  end

  # attr_writer override for body to scrub html
  def body=(bodycontent)
    write_attribute(:body, self.cleanup_html(bodycontent))
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

  def pending_expert_response_edit_notification?
    Notification.where(notifiable_id: self.id, notification_type: Notification::AAE_EXPERT_RESPONSE_EDIT, delivery_time: Time.now..Settings.expert_response_edit_interval.from_now).size > 0
  end

  def pending_submitter_response_edit_notification?
    Notification.where(notifiable_id: self.id, notification_type: Notification::AAE_EXPERT_RESPONSE_EDIT_TO_SUBMITTER, delivery_time: Time.now..Settings.expert_response_edit_interval.from_now).size > 0
  end

  private

  def set_public_flag
    if(self.resolver_id.blank?)
      self.is_expert = false
    else
      self.is_expert = true
    end
    true
  end

  def check_first_response
    if(self.question.initial_response_id.blank?)
      self.question.update_attributes({initial_response_id: self.id,
                                      initial_response_time: self.created_at - self.question.created_at,
                                      initial_response_at: self.created_at,
                                      initial_responder_id: self.resolver_id})
    end
  end

  def index_parent_question
    QuestionsIndex::Question.import self.question
  end

  def update_question_data
    self.question.update_data_cache
  end

end
