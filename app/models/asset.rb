class Asset < ActiveRecord::Base
  belongs_to :assetable, :polymorphic => true
  delegate :url, :to => :attachment
end

class Response::Image < Asset
  has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
end

class Question::Image < Asset
  has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
end