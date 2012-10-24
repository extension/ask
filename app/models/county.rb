# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class County < ActiveRecord::Base
  extend CacheTools

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

  def self.find_by_geoip(ipaddress = Settings.request_ip_address,cache_options = {})
    cache_key = self.get_cache_key(__method__,{ipaddress: ipaddress})
    Rails.cache.fetch(cache_key,cache_options) do
      if(geoname = GeoName.find_by_geoip(ipaddress))
        self.find_by_name(geoname.county)
      else
        nil
      end
    end
  end

end
