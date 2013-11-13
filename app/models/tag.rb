class Tag < ActiveRecord::Base
  has_many :taggings
  validates_uniqueness_of :name
  
  # remove extra whitespace from these attributes
  auto_strip_attributes :name, :squish => true
  
  scope :used_at_least_once, joins(:taggings).group("tags.id").having("COUNT(taggings.id) > 0").select("tags.*, COUNT(taggings.id) AS tag_count")
  scope :not_used, includes(:taggings).group("tags.id").having("COUNT(taggings.id) = 0")
  scope :tags_with_open_question_frequency, lambda {|tags| joins("JOIN taggings ON taggings.tag_id = tags.id JOIN questions on questions.id = taggings.taggable_id")
                                                      .where("tags.id IN (#{tags.map{|t| t.id}.join(',')})")
                                                      .where("taggable_type = 'Question'")
                                                      .where("status_state = #{Question::STATUS_SUBMITTED}")
                                                      .group("tags.id")
                                                      .select("tags.*, COUNT(taggings.id) AS open_question_count")
                                                    }
  
  # normalize tag names 
  # convert whitespace to single space, underscores to space, yank everything that's not alphanumeric : - or whitespace (which is now single spaces)   
  def self.normalizename(name)
    # make an initial downcased copy - don't want to modify name as a side effect
    returnstring = name.downcase
    # now, use the replacement versions of gsub and strip on returnstring
    # convert underscores to spaces
    returnstring.gsub!('_',' ')
    # get rid of anything that's not a "word", not space, not : and not - 
    returnstring.gsub!(/[^\w :-]/,'')
    # reduce multiple spaces to a single space
    returnstring.gsub!(/ {2,}/,' ')
    # remove leading and trailing whitespace
    returnstring.strip!
    returnstring
  end
  
end
