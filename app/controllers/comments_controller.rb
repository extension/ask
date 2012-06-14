
class CommentsController < ApplicationController
  before_filter :authenticate_user!, only: [:create, :update]
  
  def create 
    @comment = Comment.new(params[:comment])
    @comment.user = current_user
    if !@comment.save
      @errors = @comment.errors.full_messages.to_sentence
    else
      @question = @comment.question
      # if parent_comment_id exists, we're only going to pull the parent comment and it's subtree, 
      # because this is getting called from the parent comment's view page
      if params[:parent_comment_id].blank?
        @comments = @question.comments
        @parent_comment = nil
      else
        @comments = Comment.find(params[:parent_comment_id]).subtree
        @parent_comment = @comment
      end
    end
    
    respond_to do |format|
      format.js {render :template => 'comments/comment_changed'}
    end
  end
  
  def update 
    @comment = Comment.find(params[:id])
    if @comment.user_id == current_user.id
      if !@comment.update_attributes(params[:comment])
        @errors = @comment.errors.full_messages_to_sentence
      else
        @question = @comment.question
        # if parent_comment_id exists, we're only going to pull the parent comment and it's subtree, 
        # because this is getting called from the parent comment's view page as the parent comment is 
        # getting updated and we're only showing the parent and it's children on it's view page
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
      format.js {render :template => 'comments/comment_changed'}
    end
  end
  
  def destroy
    comment = Comment.find(params[:id])
    @question = comment.question
    @comments = @question.comments
    if comment.user_id == current_user.id
      comment.destroy
      # if parent_comment_id exists, we're going to redirect back to the question's show page, 
      # since we're on the comment's view page and the comment will be going away. 
      # the comment's children and descendants will be moving up a level in the comment hierarchy.
      if params[:parent_comment_id].blank?
        @parent_comment = false
      else
        @parent_comment = true
      end
    else
      @errors = "You cannot delete this comment as you are not the author."
    end
    respond_to do |format|
      format.js {render :template => 'comments/comment_deleted'}
    end
  end
  
  def show
    @comment = Comment.find_by_id(params[:id])
    if !@comment || @comment.created_by_blocked_user?  
      return record_not_found
    end
  end
  
end
