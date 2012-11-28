# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require 'rubygems'
require 'thor'

class CronTasks < Thor
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

    def create_evaluation_notifications
      notification_count = 0
      question_count = 0

      Question.evaluation_pool.each do |question|
        question_count += 1
        if(notification = question.create_evaluation_notification)
          notification_count += 1
        end
      end
      puts "Created #{notification_count} evaluation request notifications for the #{question_count} questions closed #{Settings.days_closed_for_evaluation} days ago"
    end

  end


  desc "evaluation_notifications", "Create evaluation request notifications for the closed questions"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def evaluation_notifications
    load_rails(options[:environment])
    create_evaluation_notifications
  end

  desc "daily", "All daily cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def daily
    load_rails(options[:environment])
    create_evaluation_notifications
  end

end

CronTasks.start