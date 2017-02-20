# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require 'rubygems'
require 'thor'
require 'csv'

class DataExport < Thor
  include Thor::Actions

  # these are not the tasks that you seek
  no_tasks do

    # load rails based on environment
    def load_rails(environment)
      if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
        ENV["RAILS_ENV"] = environment
      end
      require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
    end

  end

  desc "group_connection_counts", "Group Member and Question Event Data"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :output_file, :aliases => "-o", :desc => "Output File", :required => true
  def group_connection_counts
    load_rails(options[:environment])
    output_file = options[:output_file]
    say("Writing group results to #{output_file}")
    CSV.open(output_file,'wb') do |csv|
      headers = ['Group ID','Group Name','active?','test?','members','available assignees','question events','questions']
      csv << headers
      group_count = 0
      total_groups = Aae::Application::Group.count
      Aae::Application::Group.find_each do |g|
        group_count += 1
        say("Processing Group ##{group_count} of #{total_groups} (ID: #{g.id})")
        row = []
        row << g.id
        row << g.name
        row << g.group_active?
        row << g.is_test?
        row << g.users.valid_users.count
        row << g.assignees.count
        row << g.all_question_events.count
        row << g.all_questions.count
        csv << row
      end
    end
  end
end

DataExport.start
