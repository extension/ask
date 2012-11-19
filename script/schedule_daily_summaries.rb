# encoding: UTF-8
# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

@mydatabase = ActiveRecord::Base.connection.instance_variable_get("@config")[:database]

Notification.create(notification_type: Notification::AAE_DAILY_SUMMARY, created_by:1, recipient_id: 1, delivery_time: Settings.daily_summary_delivery_time)