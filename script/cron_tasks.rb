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
    
    def create_daily_summary_notification
      Notification.create(notification_type: Notification::AAE_DAILY_SUMMARY, created_by:1, recipient_id: 1, delivery_time: Settings.daily_summary_delivery_time)
      puts "Created notification for daily summary emails"
    end
    
    def create_daily_handling_reminder_notification
      Notification.create(notification_type: Notification::AAE_EXPERT_HANDLING_REMINDER, created_by:1, recipient_id: 1, delivery_time: Settings.daily_handling_reminder_delivery_time)
      puts "Created notification for daily handling reminder emails"
    end

    def create_daily_away_reminder_notification
      Notification.create(notification_type: Notification::AAE_EXPERT_AWAY_REMINDER, created_by:1, recipient_id: 1, delivery_time: Settings.daily_away_reminder_delivery_time)
      puts "Created notification for daily away reminder emails"
    end
    
    def clean_up_mailer_caches
      MailerCache.delete_all(["created_at < ?", 2.months.ago])
      puts "Cleaned up Mailer Caches more than 2 months old"
    end

    def check_dj_queue
    late_count = Delayed::Job.where("run_at < ?", Time.now).count
    $stderr.puts "Check to see if delayed_job died. #{late_count} job(s) waiting to be sent. " if late_count > 0
    end

    def flag_accounts_for_search_update
      User.needs_search_update.all.each do |u|
        # merely updating the account should trigger solr
        u.update_attributes({needs_search_update: false})
      end
      Sunspot.commit
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
    create_daily_summary_notification
    create_daily_handling_reminder_notification
    create_daily_away_reminder_notification
    clean_up_mailer_caches
    check_dj_queue
  end

  desc "hourly", "All hourly cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def hourly
    load_rails(options[:environment])
    flag_accounts_for_search_update
  end 

  #debug block; test a specific cron task in development 
  desc "debug", "Test a specific cron task in your development environment"
  method_option :environment,:default => 'development', :aliases => "-e", :desc => "Rails environment"
  def debug
    load_rails(options[:environment])
    #add your specific cron task you would like to test here
    #ie, to test create_daily_away_reminder_notification just uncomment out the line below
    #create_daily_away_reminder_notification
    #then run 'script/cron_tasks.rb debug' in development to test
  end 
end

CronTasks.start