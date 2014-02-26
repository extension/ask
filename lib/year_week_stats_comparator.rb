# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class YearWeekStatsComparator < Hash
  extend YearWeek

  def min_yearweek
    yearweeks = []
    self.each do |label,yws_hash|
      yearweeks << yws_hash.yearweeks.sort.first
    end
    yearweeks.min
  end

  def max_yearweek
    yearweeks = []
    self.each do |label,yws_hash|
      yearweeks << yws_hash.yearweeks.sort.last
    end
    yearweeks.max
  end

  def yearweeks
    begin
      self.class.yearweeks_between_yearweeks(min_yearweek,max_yearweek)
    rescue
      []
    end
  end


  def to_graph_data(hashvalue,options = {})
    hashed_data = {}
    relative_to = options[:relative_to]
    relative_percentage = options[:relative_percentage].nil? ? false : options[:relative_percentage]
    returndata = []
    value_data = []
    self.yearweeks.each do |yearweek|
      yearweek_date = self.class.yearweek_date(yearweek)
      self.each do |label,yws_hash|
        hashed_data[label] ||= []
        value = 0
        if(yws_hash[yearweek])
          if(relative_to)
            dividend = yws_hash[yearweek][hashvalue] || 0
            divisor = yws_hash[yearweek][relative_to] || 0
            value = (divisor > 0) ? dividend/divisor : 0
            value = (value * 100) if relative_percentage
          else
            value = yws_hash[yearweek][hashvalue] || 0
          end
        end
        hashed_data[label] << [yearweek_date,value.to_f]
      end
    end
    hashed_data.values
  end

  def to_graph_labels
    self.keys
  end
end