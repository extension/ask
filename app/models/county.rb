class County < ActiveRecord::Base
  has_many :user_counties
  has_many :users, :through => :user_counties
  has_many :group_counties
  has_many :groups, :through => :group_counties
  belongs_to :location
  
  def name
    if self.censusclass == "C7"
      # return self.name + " (Non-county incorporation)"
      return self[:name]
    else
      return self[:name] + " County"
    end
  end
    
end
