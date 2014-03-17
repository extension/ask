# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

module ExpertDataHelper

  # code from: https://github.com/ripienaar/mysql-dump-split
  def humanize_bytes(bytes,defaultstring='')
    if(!bytes.nil? and bytes != 0)
      units = %w{B KB MB GB TB}
      e = (Math.log(bytes)/Math.log(1024)).floor
      s = "%.1f"%(bytes.to_f/1024**e)
      s.sub(/\.?0*$/,units[e])
    else
      defaultstring
    end
  end
  
  def response_rate(response_rate)
    if(response_rate[:eligible] >= 0)
      ratio = (response_rate[:responses] / response_rate[:eligible]) * 100
      "#{number_to_percentage(ratio,precision: 1)} (#{number_with_delimiter(response_rate[:responses].to_i)} / #{number_with_delimiter(response_rate[:eligible])})".html_safe
    else
      "n/a"
    end
  end

  def seen_pct(stats)
    if(stats['pages'] and stats['pages'] > 0)
      seen = stats['seen'] || 0
      number_to_percentage((seen/stats['pages'])*100, precision: 1)
    else
      'n/a'
    end
  end

  def week_picker_date
    (year,week) = Question.latest_year_week
    (sow,eow) = Question.date_pair_for_year_week(year,week)

    if(@date and @date < eow)
      (at_date_year,at_date_week) = Analytic.year_week_for_date(date)
      (sow,eow) = Analytic.date_pair_for_year_week(at_date_year,at_date_week)
    end
    sow.strftime('%Y-%m-%d')
  end



  def year_week_for_last_week
    (year,week) = Question.latest_year_week
    "#{year} Week ##{week}".html_safe
  end


  def date_range_for_last_week
    (year,week) = Question.latest_year_week
    (sow,eow) = Question.date_pair_for_year_week(year,week)
    "#{sow.strftime("%b&nbsp;%d")} - #{eow.strftime("%b&nbsp;%d")}".html_safe
  end


  def question_filter_text(filter_hash)
    string_array = []
    filter_hash.each do |filter_key,items|
      if(filter_key == 'date_range')
        # TODO something
      else
        string_array << "<strong>#{filter_key.gsub('_',' ').capitalize}</strong>: #{items.map(&:name).join(' or ')}"
      end
    end
    string_array.join(' and ').html_safe
  end

end
