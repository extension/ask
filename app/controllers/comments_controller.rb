# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class CommentsController < ApplicationController
  before_filter :authenticate_user!, only: [:create, :update]
  
  def create 
    @comment = Comment.new(params[:comment])
    @errors = nil
    @comment.user = current_user
    @question = @comment.question
    
    if !@comment.save
      @errors = @comment.errors.full_messages.to_sentence
    else
      @question = @comment.question
      @comment = Comment.new
      # if parent_comment_id exists, we're only going to pull the parent comment and it's subtree, 
      # because this is getting called from the parent comment's view page
      if params[:parent_comment_id].blank?
        @question_comments = @question.comments
        @parent_comment = nil
      else
        @question_comments = Comment.find(params[:parent_comment_id]).subtree
        @parent_comment = @comment
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def update 
    @comment = Comment.find(params[:id])
    if @comment.user_id == current_user.id
      if !@comment.update_attributes(params[:comment])
        @errors = @comment.errors.full_messages.to_sentence
      else
        @question = @comment.question
        if params[:parent_comment_id].blank?
          @comments = @question.comments
          @parent_comment = nil
        else
          @parent_comment = Comment.find(params[:parent_comment_id])
          @comments = @parent_comment.subtree
        end
      end
    else
      @errors = "You cannot edit this comment as you are not the author."
    end
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    
    if @comment.user_id == current_user.id
      if @comment.persisted?
        @comment_id = @comment.id
        if !@comment.destroy
          @errors = @comment.errors.full_messages.to_sentence
        end
      else
        return render :nothing => true
      end
    
      respond_to do |format|
        format.js
      end
    end
  end
  
  def reply
    @parent_comment = Comment.find_by_id(params[:comment_id])
    @question = @parent_comment.question
    @comment = Comment.new
    
    respond_to do |format|
      format.js
    end
  end
  
  def show
    @comment = Comment.find_by_id(params[:id])
    if !@comment || @comment.created_by_blocked_user?  
      return record_not_found
    end
  end
  
  def edit
    @comment = Comment.find_by_id(params[:id])
    @question = @comment.question
    
    respond_to do |format|
      format.js
    end
  end
  
  def cancel_edit
    @comment = Comment.find(params[:comment_id])
  
    respond_to do |format|
      format.js
    end
  end
  
  def cancel_reply
    @comment = Comment.find(params[:comment_id])
  
    respond_to do |format|
      format.js
    end
  end
  
end