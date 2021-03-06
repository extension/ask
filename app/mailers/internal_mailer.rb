# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class InternalMailer < BaseMailer

  def aae_assignment(options = {})
    @user = options[:user]
    @question = options[:question]
    @subject = "You have a new Ask an Expert question (##{@question.id})"
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @respond_by = @assigned_at + Settings.aae_escalation_delta.hours
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "You have a new Ask an Expert question (##{@question.id})"

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
    @subject = "Your Ask an Expert question has been reassigned (Question:#{@question.id})"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "Your Question Has Been Reassigned"

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
    @subject = "Ask an Expert Daily Summary"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "Ask an Expert Daily Summary"

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
    @subject = "Your Ask an Expert question was edited by the submitter (Question:#{@question.id})"
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @respond_by = @assigned_at + Settings.aae_escalation_delta.hours
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "A Question Assigned to You Has Been Edited"

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

  def aae_response_edit(options = {})
    @user = options[:user]
    @question = options[:question]
    @response = options[:response]
    @subject = "One of your Ask an Expert responses was edited (Question:#{@question.id})"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "One of your Ask an Expert responses was edited"

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

  def aae_public_response(options = {})
    @user = options[:user]
    @response = options[:response]
    @question = @response.question
    @subject = "Your Ask an Expert question has a new response from the question submitter (Question:#{@question.id})"
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @respond_by = @assigned_at + Settings.aae_escalation_delta.hours
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "New response to a question assigned to you"

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
    @subject = "Your Ask an Expert question has been rejected (Question:#{@question.id})"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "Your Assigned Question Was Rejected"

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

  def aae_internal_comment(options = {})
    @user = options[:user]
    @question = options[:question]
    @internal_comment_event = options[:internal_comment_event]
    @internal_comment = @internal_comment_event.response
    @subject = "Another expert has posted a comment to your Ask an Expert question (Question:#{@question.id})"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @title = "New Note on a Question Assigned To You"

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

  def aae_assignment_group(options = {})
    @user = options[:user]
    @question = options[:question]
    @subject = "#{@question.assigned_group.name} has a new Ask an Expert question (##{@question.id})"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "Your Group has a New Question"

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

  def aae_question_activity(options = {})
    @user = options[:user]
    @question = options[:question]
    @subject = "New Ask an Expert activity on question #{@question.id}"
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @respond_by = @assigned_at + Settings.aae_escalation_delta.hours
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "New Activity on a Question"

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

  def aae_expert_tag_edit(options = {})
    @user = options[:user]
    @subject = "Your Profile tags have been edited"
    @title = "Your Profile tags have been edited"

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

  def aae_expert_vacation_edit(options = {})
    @user = options[:user]
    @subject = "Your Ask an Expert away status was changed"
    @title = "Your Ask an Expert away status was changed"

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

  def aae_expert_location_edit(options = {})
    @user = options[:user]
    @subject = "Your Ask an Expert expertise location was changed"
    @title = "Your Ask an Expert expertise location was changed"

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

  def aae_expert_group_edit(options = {})
    @user = options[:user]
    @subject = "Your Ask an Expert group membership was changed"
    @title = "Your Ask an Expert group membership was changed"

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

  def aae_expert_handling_reminder(options = {})
    @user = options[:user]
    @question = options[:question]
    @assigned_at = @user.time_for_user(@question.last_assigned_at)
    @subject = "Ask an Expert Handling Reminder: Question #{@question.id}"
    @title = "Handling Reminder: Question #{@question.id}"

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

  def aae_expert_away_reminder(options = {})
    @user = options[:user]
    if @user.vacated_aae_at
      @away_date = @user.vacated_aae_at.strftime('%B %d, %Y')
    else
      @away_date = "<away date>"
    end
    @subject = "Reminder: Your status is set to away!"

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

  def data_download_available(options = {})
    @download = options[:download]
    @recipient = options[:recipient]
    @subject = "Ask an Expert: Your download is now available"

    if(!@recipient.email.blank?)
      return_email = mail(to: @recipient.email, subject: @subject)
    end

    return_email
  end

end
