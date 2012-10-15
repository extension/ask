#!/usr/bin/env ruby
require 'rubygems'
require 'csv'

###
## BEFORE RUNNING: The input file must be cleaned of quotation marks, or the script will fail.
## sed 's/\"//g' PATH_TO_FILE_TO_CLEAN > PATH_TO_OUTPUT_FILE
## Remove all lines which don't match Populated (Populated Places are what we're interested in)
## sed q NationalFile_20121001.txt > geoname_clean.txt && sed '/Populated/!d' NationalFile_20121001.txt >> geoname_clean.txt
###

if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = 'development'
end
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")


geoname_data_file = Settings.geoname_data_file

def process(csv_array)  # makes arrays of hashes out of CSV's arrays of arrays
  return result if csv_array.nil? || csv_array.empty?
  csv_array.each do |row|
    if row["FEATURE_CLASS"] == 'Populated Place'
      GeoName.create(:id => row["FEATURE_ID"], :feature_name => row["FEATURE_NAME"], :feature_class => row["FEATURE_CLASS"], :state_alpha => row["STATE_ALPHA"], :county_name => row["COUNTY_NAME"], :prim_lat_dec => row["PRIM_LAT_DEC"], :prim_long_dec => row["PRIM_LONG_DEC"], :map_name => row["MAP_NAME"], :date_created => row["DATE_CREATED"], :date_edited => row["DATE_EDITED"])
    end
  end
end

csv_data = CSV.read( geoname_data_file, {:col_sep => '|',:headers => true,:encoding => Encoding::UTF_8})
process(csv_data)
