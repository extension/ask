# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class YearWeekStats < Hash
  extend YearWeek

  def to_graph_data(hashvalue,options = {})
    showrolling = options[:showrolling].nil? ? true : options[:showrolling]
    relative_to = options[:relative_to]
    relative_percentage = options[:relative_percentage].nil? ? false : options[:relative_percentage]
    returndata = []
    value_data = []
    rolling_data = []
    running_total = 0
    loopcount = 0
    self.yearweeks.each do |yearweek|
      value = 0
      loopcount += 1
      yearweek_date = self.class.yearweek_date(yearweek)
      if(relative_to)
        dividend = self[yearweek][hashvalue] || 0
        divisor = self[yearweek][relative_to] || 0
        value = (divisor > 0) ? dividend/divisor : 0
        value = (value * 100) if relative_percentage
      else
        value = self[yearweek][hashvalue] || 0
      end
      value_data << [yearweek_date,value.to_f]
      if(showrolling)
        running_total += value
        rolling = running_total / loopcount
        rolling_data << [yearweek_date,rolling.to_f]
      end
    end

    if(showrolling)
      returndata = [value_data,rolling_data]
    else
      returndata = [value_data]
    end

    returndata
  end

  def max_for_hashvalue(hashvalue,nearest = nil)
    distribution = []
    self.yearweeks.each do |yearweek|
      if(!self[yearweek][hashvalue].nil?)
        distribution << self[yearweek][hashvalue]
      end
    end
    returnmax = distribution.max
    if(nearest)
      returnmax = returnmax + nearest - (max % nearest)
    end
    returnmax
  end

  def max_yearweek_for_hashvalue(hashvalue,nearest = nil)
    yearweeks_with_hashvalue = {}
    self.yearweeks.each do |yearweek|
      if(!self[yearweek][hashvalue].nil?)
        yearweeks_with_hashvalue[yearweek] = self[yearweek][hashvalue]
      end
    end
    yearweeks_with_hashvalue.max_by{|k,v| v}
  end

  def sum_for_hashvalue(hashvalue)
    distribution = []
    self.yearweeks.each do |yearweek|
      if(!self[yearweek][hashvalue].nil?)
        distribution << self[yearweek][hashvalue]
      end
    end
    returnsum = distribution.sum
    returnsum
  end

  def yearweeks
    if(!@yearweeks)
      @yearweeks = self.keys.reject{|keyname| keyname == :flags}.sort
    end
    @yearweeks
  end

  def flags
    if(self[:flags])
      self[:flags]
    else
      {}
    end
  end

  def to_percentile_graph_data(options = {})
    return [] if !flags[:percentiles]
    hashed_data = {}
    self.yearweeks.each do |yearweek|
      yearweek_date = self.class.yearweek_date(yearweek)
      hashed_data[:mean] ||= []
      hashed_data[:mean] << [yearweek_date,self[yearweek][:mean]]
      Settings.display_percentiles.each do |pct|
        hashed_data[pct] ||= []
        hashed_data[pct] << [yearweek_date,self[yearweek][pct]]
      end

    end
    hashed_data.values
  end

  def to_percentile_graph_labels(options = {})
    return [] if !flags[:percentiles]
    ['Average Views'] + Settings.display_percentiles_labels
  end

  def count_for_hashvalue(hashvalue,minval = nil)
    distribution = []
    self.yearweeks.each do |yearweek|
      if(!self[yearweek][hashvalue].nil?)
        if(!minval.nil?)
          distribution << self[yearweek][hashvalue] if self[yearweek][hashvalue] >= minval
        else
          distribution << self[yearweek][hashvalue]
        end
      end
    end
    returncount = distribution.size
    returncount
  end
end