# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class BaseMailer < ActionMailer::Base
  helper ApplicationHelper
  default_url_options[:host] = Settings.urlwriter_host
  default from: Settings.email_from_address
  default bcc: Settings.email_bcc_address
  helper_method :ssl_root_url, :ssl_webmail_logo, :is_demo?


  def save_sent_email_for_recipient(email,recipient,options = {})
    if(recipient.is_a?(Person))
      create_options = {person: recipient, markup: email.body.to_s}
    elsif(recipient.is_a?(String))
      create_options = {email: recipient, markup: email.body.to_s}
    end
    create_options.merge!({notification: options[:notification]}) if(!options[:notification].blank?)
    SentEmail.create(create_options)
  end

  def ssl_root_url
    if(Settings.app_location != 'localdev')
      root_url(protocol: 'https')
    else
      root_url
    end
  end

  def ssl_webmail_logo
    parameters = {mailer_cache_id: @mailer_cache.id, format: 'png'}
    if(Settings.app_location != 'localdev')
      webmail_logo_url(parameters.merge({protocol: 'https'}))
    else
      webmail_logo_url(parameters)
    end
  end

  def is_demo?
    Settings.app_location != 'production'
  end

  def create_mail(options = {})
    mailoptions = options.dup
    send_in_demo = mailoptions.delete(:send_in_demo)
    if(is_demo? and !send_in_demo)
      mailoptions[:subject] = "[#{options[:to]}] #{options[:subject]}"
      mailoptions[:to] = Settings.email_test_address
      mailoptions[:cc] = nil
      mailoptions[:bcc] = nil
    end
    mail(mailoptions)
  end

end
