class Tag < ActiveRecord::Base
  has_many :taggings
  validates_uniqueness_of :name

  # remove extra whitespace from these attributes
  auto_strip_attributes :name, :squish => true

  scope :used_at_least_once, joins(:taggings).group("tags.id").having("COUNT(taggings.id) > 0").select("tags.*, COUNT(taggings.id) AS tag_count")
  scope :not_used, includes(:taggings).group("tags.id").having("COUNT(taggings.id) = 0")

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

  def self.tags_with_open_question_frequency(tag_list)
    return Tag.joins("JOIN taggings ON taggings.tag_id = tags.id JOIN questions on questions.id = taggings.taggable_id")
              .where("tags.id IN (#{tag_list.map{|t| t.id}.join(',')})")
              .where("taggable_type = 'Question'")
              .where("status_state = #{Question::STATUS_SUBMITTED}")
              .group("tags.id")
              .select("tags.*, COUNT(taggings.id) AS open_question_count")
  end

  def replace_with_tag(replacement_tag)
    connection.clear_query_cache
    # update but ignore existing key constraints
    self.connection.execute("UPDATE IGNORE taggings SET tag_id = #{replacement_tag.id} WHERE tag_id = #{self.id}")
    self.destroy # should clean up stragglers
  end

  def tagged_objects_hash
    returnhash = {}
    # get a hash of affected objects
    Tagging.where(tag_id: self.id).all.each do |tagging|
      if(returnhash[tagging.taggable_type])
        returnhash[tagging.taggable_type].push(tagging.taggable_id)
      else
        returnhash[tagging.taggable_type] = [tagging.taggable_id]
      end
    end
    returnhash
  end

end
