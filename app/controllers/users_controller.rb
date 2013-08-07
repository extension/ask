# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class UsersController < ApplicationController
  layout 'public'
  
  before_filter :set_format, :only => [:show]
  
  def show
    @user = User.valid_users.find_by_id(params[:id])
    if @user.blank?
      flash[:error] = "This user does not exist."
      return redirect_to root_url
    end
    @answered_questions = @user.answered_questions.public_visible.limit(10)
    @open_questions = @user.open_questions.public_visible.limit(10)
  end
  
  def retired
  end
  
  def comment_notification_subscription
    question = Question.find_by_question_fingerprint(params[:fingerprint].strip)
    user = User.find_by_id(params[:id])
    subscription_election = params[:subscribe].strip
    
    if question.present? && user.present? && ['yes', 'no'].include?(subscription_election)
      if subscription_election == 'yes'
        Preference.create_or_update(user, Preference::NOTIFICATION_COMMENTS, true, nil, question.id)
        flash[:notice] = "We have subscribed you to the comment notifications for this question. You can unsubscribe at any time by clicking the subscription button below."
      elsif subscription_election == 'no'
        Preference.create_or_update(user, Preference::NOTIFICATION_COMMENTS, false, nil, question.id)
        flash[:notice] = "We have unsubscribed you to the comment notifications for this question. You can resubscribe to comment notifications at any time by clicking the subscription button below."
      end
    else
      flash[:notice] = "The question or the user specified could not be found with this subscription election."
      return redirect_to root_url
    end
    
    redirect_to question_url(question)
  end
  
  
end 