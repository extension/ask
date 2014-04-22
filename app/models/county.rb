# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class County < ActiveRecord::Base
  include CacheTools

  # special cases of alternate names for geo areas
  LOCATION_ALASKA = 10
  LOCATION_LOUISIANA = 28

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
      self[:name]
    else
      if self[:name] == 'All'
        return "Entire state"
      else
        if(self.location_id == LOCATION_ALASKA)
          case self.censusclass
          # H6 == city/muncipality - don't set a geo_term
          when 'H5'
            geo_term = 'Census Area'
          when 'H1'
            geo_term = 'Borough'
          end

        elsif(self.location_id == LOCATION_LOUISIANA)
          geo_term = 'Parish'
        else
          geo_term = 'County'
        end
        if(geo_term.blank?)
          self[:name]
        else
          "#{self[:name]} #{geo_term}"
        end
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
