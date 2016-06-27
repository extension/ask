# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class GroupMailer < BaseMailer

  def group_user_join(options = {})
    @user = options[:user]
    @group = options[:group]
    @new_member = options[:new_member]
    @subject = "Someone joined your Ask an Expert Group: #{@group.name}"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "Someone has joined #{@group.name}"

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

  def group_user_left(options = {})
    @user = options[:user]
    @group = options[:group]
    @former_member = options[:former_member]
    @subject = "Someone left your Ask an Expert Group: #{@group.name}"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "Someone has left #{@group.name}"

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

  def group_leader_join(options = {})
    @user = options[:user]
    @group = options[:group]
    @new_leader = options[:new_leader]
    @subject = "New Leader for Ask an Expert Group: #{@group.name}"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "New Leader for #{@group.name}"

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

  def group_leader_left(options = {})
    @user = options[:user]
    @group = options[:group]
    @former_leader = options[:former_leader]
    @subject = "A leader left your Ask an Expert Group: #{@group.name}"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    @title = "A Leader Has Left #{@group.name}"

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

end
