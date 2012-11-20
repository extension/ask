# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class InternalMailer < ActionMailer::Base
  helper ApplicationHelper
  default_url_options[:host] = Settings.urlwriter_host
  default from: "aae-notify@extension.org"
  default bcc: "systemsmirror@extension.org"
  helper_method :ssl_root_url, :ssl_webmail_logo
  
  
  def aae_assignment(options = {})
    @user = options[:user]
    @question = options[:question]
    @subject = "[eXtension Question:#{@question.id}] Incoming question assigned to you"
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @respond_by = @assigned_at + Settings.aae_escalation_delta.hours
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end
      
      return_email = mail(to: @user.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
  end
  
  def aae_reassignment(options = {})
    @user = options[:user]
    @question = options[:question]
    @subject = "[eXtension Question:#{@question.id}] Incoming question reassigned."
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end
      
      return_email = mail(to: @user.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
  end
  
  def aae_daily_summary(options = {})
    @user = options[:user]
    @groups = options[:groups]
    @subject = "eXtension Initiative: Ask an Expert Daily Summary"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @groups[0])
      end
      
      return_email = mail(to: @user.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
  end
  
  def aae_public_edit(options = {})
    @user = options[:user]
    @question = options[:question]
    @subject = "[eXtension Question:#{@question.id}] Incoming question edited by submitter"
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @respond_by = @assigned_at + Settings.aae_escalation_delta.hours
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end
      
      return_email = mail(to: @user.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
  end
  
  def aae_public_comment(options = {})
    @user = options[:user]
    @comment = options[:comment]
    @question = @comment.question
    @subject = "[eXtension Question:#{@question.id}] A question you have been assigned has a new comment."
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @respond_by = @assigned_at + Settings.aae_escalation_delta.hours
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end
      
      return_email = mail(to: @user.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
  end
  
  def aae_reject(options = {})
    @rejected_event = options[:rejected_event]
    @question = @rejected_event.question
    @user = options[:user]
    @subject = "[eXtension Question:#{@question.id}] Incoming question rejected"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end
      
      return_email = mail(to: @user.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
  end
  
  def aae_expert_comment(options = {})
    @user = options[:user]
    @group = options[:group]
    @question = options[:question]
    @expert_comment_event = options[:expert_comment_event]
    @expert_comment = @expert_comment_event.response
    @subject = "[eXtension Question:#{@question.id}] A question you have been assigned has a new comment from an expert"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end
      
      return_email = mail(to: @user.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
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

end
