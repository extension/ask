# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class PublicMailer < BaseMailer

  def public_expert_response(options = {})
    @user = options[:user]
    @expert = options[:expert]
    @question = options[:question]
    @subject = "Your Ask an Expert question has an answer (Question:#{@question.id})"
    @response = @question.responses.last
    @title = "Your Question Has a Response"

    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]



    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end

      set_from_address_if_bonnie_plants
      return_email = mail(from: @from_address, to: @user.email, subject: @subject)

      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end

    # the email if we got it
    return_email
  end

  def public_submission_acknowledgement(options = {})
      @user = options[:user]
      @question = options[:question]
      @subject = "Thank you for your Ask an Expert question (Question:#{@question.id})"
      @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
      @title = "Your Question Has Been Submitted"



      if(!@user.email.blank?)
        if(@will_cache_email)
          # create a cached mail object that can be used for "view this in a browser" within
          # the rendered email.
          @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
        end

        set_from_address_if_bonnie_plants
        return_email = mail(from: @from_address, to: @user.email, subject: @subject)

        if(@mailer_cache)
          # now that we have the rendered email - update the cached mail object
          @mailer_cache.update_attribute(:markup, return_email.body.to_s)
        end
      end

    # the email if we got it
    return_email
  end

  def public_rejection_location(options = {})
      @user = options[:user]
      @question = options[:question]
      @subject = "Your Ask an Expert question has been rejected (Question:#{@question.id})"
      @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
      @title = "Your Question Has Been Rejected"
      @group = @question.assigned_group


      if(!@user.email.blank?)
        if(@will_cache_email)
          # create a cached mail object that can be used for "view this in a browser" within
          # the rendered email.
          @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
        end

        set_from_address_if_bonnie_plants
        return_email = mail(from: @from_address, to: @user.email, subject: @subject)

        if(@mailer_cache)
          # now that we have the rendered email - update the cached mail object
          @mailer_cache.update_attribute(:markup, return_email.body.to_s)
        end
      end

    # the email if we got it
    return_email
  end


  def public_evaluation_request(options = {})
    @user = options[:user]
    @question = options[:question]
    @example_survey = options[:example_survey]

    @subject = "Tell us about your Ask an Expert experience (Question:#{@question.id})"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "Ask an Expert Evaluation"

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

  def expert_response_edit(options = {})
    @user = options[:user]
    @question = options[:question]
    @response = options[:response]

    @subject = "An expert has edited a response to your Ask an Expert question (Question:#{@question.id})"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "An Expert Has Edited a Response To Your Question"

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

  private

  def set_from_address_if_bonnie_plants
    if @question.assigned_group.present? && @question.assigned_group.is_bonnie_plants?
      @from_address = %("Bonnie Plants Ask an Expert" <aae-notify@extension.org>)
    else
      @from_address = Settings.email_from_address
    end
  end

end
