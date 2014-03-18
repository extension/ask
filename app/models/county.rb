# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class County < ActiveRecord::Base
  include CacheTools

  has_many :user_counties
  has_many :users, :through => :user_counties
  has_many :group_counties
  has_many :groups, :through => :group_counties
  belongs_to :location
  has_many :users_with_origin, :class_name => "User", :foreign_key => "county_id"
  has_many :questions_with_origin, :class_name => "Question", :foreign_key => "county_id"

  def name
    if self.censusclass == "C7"
      # return self.name + " (Non-county incorporation)"
      return self[:name]
    else
      if self[:name] == 'All'
        return "Entire state"
      else
        return self[:name] + " County"
      end
    end
  end

  def name_with_location
    "#{self.name}, #{self.location.abbreviation}"
  end

  def self.find_by_geoip(ipaddress = Settings.request_ip_address,cache_options = {})
    cache_key = self.get_cache_key(__method__,{ipaddress: ipaddress})
    Rails.cache.fetch(cache_key,cache_options) do
      if(geoname = GeoName.find_by_geoip(ipaddress))
        if(location = Location.find_by_abbreviation(geoname.state_abbreviation))
          location.counties.where(name: geoname.county).first
        else
          nil
        end
      else
        nil
      end
    end
  end

  def is_all_county?
    return self.name == 'All' && self.countycode == 0
  end

  # the spec says leading 0 is required
  # but the R maps package leaves it as numeric, so I'm doing that
  def fips(make_integer = true)
    if(make_integer)
      "#{state_fipsid}#{countycode}".to_i
    else
      "%02d" % state_fipsid + "#{countycode}"
    end
  end

end
