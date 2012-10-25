class User < ActiveRecord::Base
  has_many :authmaps
  has_many :comments
  has_many :questions
  has_many :responses
  has_many :user_locations
  has_many :user_counties
  has_many :user_preferences
  has_many :expertise_locations, :through => :user_locations, :source => :location
  has_many :expertise_counties, :through => :user_counties, :source => :county
  has_many :notification_exceptions
  has_many :group_connections, :dependent => :destroy
  has_many :group_memberships, :through => :group_connections, :source => :group, :conditions => "connection_type IN ('leader', 'member')", :order => "groups.name", :uniq => true
  has_many :ratings
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  has_many :initiated_question_events, :class_name => 'QuestionEvent', :foreign_key => 'initiated_by_id'
  has_many :answered_questions, :through => :initiated_question_events, :conditions => "question_events.event_state = #{QuestionEvent::RESOLVED}", :source => :question, :order => 'question_events.created_at DESC', :uniq => true
  has_many :open_questions, :class_name => "Question", :foreign_key => "assignee_id", :conditions => "status_state = #{Question::STATUS_SUBMITTED} AND spam = false"
  
  
  # sunspot/solr search
  searchable do
    text :name
    text :login
    text :email
    text :tag_fulltext
    boolean :retired
    boolean :is_blocked
    string :kind
  end
  
  
  devise :rememberable, :trackable, :database_authenticatable
  
  has_attached_file :avatar, :styles => { :medium => "100x100#", :thumb => "40x40#", :mini => "20x20#" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  
  validates_attachment :avatar, :size => { :less_than => 8.megabytes },
    :content_type => { :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png'] }
    
  before_update :update_vacated_aae
  
  DEFAULT_NAME = 'Anonymous'
  scope :tagged_with, lambda {|tag_id| 
    {:include => {:taggings => :tag}, :conditions => "tags.id = '#{tag_id}' AND taggings.taggable_type = 'User'"}
  }
  
  scope :with_expertise_county, lambda {|county_id| includes(:expertise_counties).where("user_counties.county_id = #{county_id}") }
  scope :with_expertise_location, lambda {|location_id| includes(:expertise_locations).where("user_locations.location_id = #{location_id}") }
  scope :question_wranglers, conditions: { is_question_wrangler: true }
  scope :active, conditions: { away: false }
  scope :route_from_anywhere, conditions: { routing_instructions: 'anywhere' }
  scope :exid_holder, conditions: { kind: 'User' }
  scope :not_retired, conditions: { retired: false }
  scope :not_blocked, conditions: { is_blocked: false }
  
  scope :tagged_with_any, lambda { |tag_list| 
        {:select => "users.*, COUNT(users.id) AS tag_count", :joins => (:tags), :conditions => "tags.name IN (#{tag_list})", :group => "users.id", :order => "tag_count DESC"}
  }
  
  
  scope :patternsearch, lambda {|searchterm|
    # remove any leading * to avoid borking mysql
    # remove any '\' characters because it's WAAAAY too close to the return key
    # strip '+' characters because it's causing a repitition search error
    # strip parens '()' to keep it from messing up mysql query
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').gsub(/\(/,'').gsub(/\)/,'').strip
    
    if sanitizedsearchterm == ''
      return []
    end
    
    # in the format wordone wordtwo?
    words = sanitizedsearchterm.split(%r{\s*,\s*|\s+})
    if(words.length > 1)
      findvalues = { 
       :firstword => words[0],
       :secondword => words[1]
      }
      conditions = ["((first_name rlike :firstword AND last_name rlike :secondword) OR (first_name rlike :secondword AND last_name rlike :firstword))",findvalues]
    else
      conditions = ["(first_name rlike ? OR last_name rlike ?)", sanitizedsearchterm, sanitizedsearchterm]
    end
    {:conditions => conditions}
  }
  
  
  def name
    if (self.first_name.present? && self.last_name.present?)
      return self.first_name + " " + self.last_name 
    elsif self.public_name.present?
      return self.public_name
    end
    return DEFAULT_NAME
  end
  
  def public_name
    if self[:public_name].present?
      return self[:public_name]
    elsif (self[:first_name].present? && self[:last_name].present?)
      return self[:first_name] + " " + self[:last_name][0,1]
    end
    return DEFAULT_NAME
  end
  
  def tag_fulltext
    self.tags.map(&:name).join(' ')
  end
  
  def member_of_group(group)
    find_group = self.group_connections.where('group_id = ?', group.id)
    !find_group.blank?
  end
  
  def leader_of_group(group)
    find_group = self.group_connections.where('group_id = ?', group.id).where('connection_type = ?', 'leader')
    !find_group.blank?
  end
  
  def self.system_user_id
    return 1
  end
  
  def self.system_user
   find(1)
  end
  
  def has_exid?
    return self.kind == 'User'
  end
  
  def retired?
    return self.retired
  end
  
  def set_tag(tag)
    if self.tags.collect{|t| t.name}.include?(Tag.normalizename(tag))
      return false
    else 
      if(tag = Tag.find_or_create_by_name(Tag.normalizename(tag)))
        self.tags << tag
        return tag
      end
    end
  end
  
  def update_vacated_aae
    if self.away_changed? 
      if self.away == true
        self.vacated_aae_at = Time.now
      else
        self.vacated_aae_at = nil
      end
    end
  end
  
  def join_group(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('group_id = ?',group.id).first)
      connection.destroy
    end
    
    self.group_connections.create(group: group, connection_type: connection_type)
    
    if connection_type == 'leader'
      GroupEvent.log_added_as_leader(group, self, self)
    else
      GroupEvent.log_group_join(group, self, self)
    end
    
    # question wrangler group?
    if(group.id == Group::QUESTION_WRANGLER_GROUP_ID)
      if(connection_type == 'leader' || connection_type == 'member')
        self.update_attribute(:is_question_wrangler, true)
      end
    end
    
  end
  
  # instance method version of aae_handling_event_count
  def aae_handling_event_count(options = {})
    myoptions = options.merge({:group_by_id => true, :limit_to_handler_ids => [self.id]})
    result = self.class.aae_handling_event_count(myoptions)
    if(result.present? && result[self.id].present?)
      returnvalues = result[self.id]
    else
      returnvalues = {:total => 0, :handled => 0, :ratio => 0}
    end
    return returnvalues
  end
   
  def self.aae_handling_event_count(options = {})
    # narrow by recipients
    !options[:limit_to_handler_ids].blank? ? recipient_condition = "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})" : recipient_condition = nil
    # default date interval is 6 months
    date_condition = "created_at > date_sub(curdate(), INTERVAL 6 MONTH)"    
    # group by user id's or user objects?
    group_clause = (options[:group_by_id] ? 'previous_handling_recipient_id' : 'previous_handling_recipient')
    
    # get the total number of handling events
    conditions = []      
    conditions << date_condition
    conditions << recipient_condition if recipient_condition.present?
    totals_hash = QuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    
    # pull all question events for where someone pulled the question from them within 24 hours and do not count those
    conditions = ["initiated_by_id <> previous_handling_recipient_id"]
    conditions << date_condition
    conditions << "duration_since_last_handling_event <= 86400"
    conditions << recipient_condition if recipient_condition.present?
    negated_hash = QuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    
    # get the total number of handling events for which I am the previous recipient *and* I was the initiator.
    conditions = ["initiated_by_id = previous_handling_recipient_id"]
    conditions << date_condition
    conditions << recipient_condition if recipient_condition.present?
    handled_hash = QuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    
    # loop through the total list, build a return hash
    # that will return the values per user_id (or user object)
    returnvalues = {}
    returnvalues[:all] = {:total => 0, :handled => 0, :ratio => 0}
    totals_hash.keys.each do |groupkey|
      total = totals_hash[groupkey]
      total = total - negated_hash[groupkey].to_i if !negated_hash[groupkey].nil? 
      handled = (handled_hash[groupkey].nil?? 0 : handled_hash[groupkey])
      # calculate a floating point ratio
      if(handled > 0)
        ratio = handled.to_f / total.to_f
      else
        ratio = 0
      end
      returnvalues[groupkey] = {:total => total, :handled => handled, :ratio => ratio}
      returnvalues[:all][:total] += total
      returnvalues[:all][:handled] += handled       
    end
    if(returnvalues[:all][:handled] > 0)
      returnvalues[:all][:ratio] = returnvalues[:all][:handled].to_f / returnvalues[:all][:total].to_f
    end

    return returnvalues
  end
    
  def leave_group(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('connection_type = ?', connection_type).where('group_id = ?',group.id).first)
      connection.destroy
      GroupEvent.log_group_leave(group, self, self)
    end
    
    # question wrangler group?
    if(group.id == Group::QUESTION_WRANGLER_GROUP_ID)
      self.update_attribute(:is_question_wrangler, false)
    end
  end
  
  def leave_group_leadership(group, connection_type)
    if(connection = GroupConnection.where('user_id =?',self.id).where('connection_type = ?', connection_type).where('group_id = ?',group.id).first)
      connection.destroy
      self.group_connections.create(group: group, connection_type: "member")
      GroupEvent.log_removed_as_leader(group, self, self)
    end
  end
    
end
