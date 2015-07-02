# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::TagsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid

  def index
    @tags_total_count = Tag.used_at_least_once.length
    # @tags = Tag.used_at_least_once.order('tags.name ASC').page(params[:page]).per(50)
    @tags = Tag.used_at_least_once.order('tags.name ASC').limit(25)
    @tag_edit_logs = TagEditLog.order("created_at DESC").limit(25)
    @unused_tag_count = Tag.not_used.length
    @longest_tags = Tag.order("LENGTH(name) desc").limit(10)
  end



  def edit
    @tag = Tag.find_by_name(params[:name])
    if !@tag
      @tag = Tag.find(params[:name])
    end
    if !@tag
      return redirect_to expert_tags_path()
    end

    @replacement_tag_placeholder = Tag.normalizename(@tag.name)
    if @tag
      @question_total_count = Question.tagged_with(@tag.id).count
      @expert_total_count = User.tagged_with(@tag.id).count
      @group_total_count = Group.tagged_with(@tag.id).count
      @total_items_tagged = @question_total_count + @expert_total_count + @group_total_count
    else
      @tag = false
      @tag_name = params[:name]
    end
  end

  def edit_confirmation
    if(!request.post?)
      return redirect_to expert_tags_path()
    end

    @current_tag = Tag.find_by_name(params[:current_tag])
    @replacement_tag = Tag.find_by_name(Tag.normalizename(params[:replacement_tag]))
    @replacement_tag_count = 0

    if @replacement_tag
      if (@current_tag.id == @replacement_tag.id)
        flash[:warning] = "The replacement tag is the same as the current tag."
        return redirect_to expert_tag_edit_path(@current_tag.name)
      end
      @replacement_tag_count = Tagging.where(tag_id: @replacement_tag.id).count
    end

    @question_total_count = Question.tagged_with(@current_tag.id).order("questions.status_state ASC").count
    @expert_total_count = User.tagged_with(@current_tag.id).count
    @group_total_count = Group.tagged_with(@current_tag.id).count
  end

  def edit_taggings
    @current_tag = Tag.find_by_id(params[:current_tag_id])
    @replacement_tag = Tag.find_or_create_by_name(Tag.normalizename(params[:replacement_tag]))
    if @current_tag != @replacement_tag
      affected_objects_hash = @current_tag.tagged_objects_hash
      @current_tag.replace_with_tag(@replacement_tag)

      # record tag and log changes
      change_hash = Hash.new
      change_hash[:tags] = {:old => @current_tag.name, :new => @replacement_tag.name}
      TagEditLog.log_edited_tags(current_user, change_hash, affected_objects_hash)

      # @current_tag is destroyed, but the object is frozen,
      # so we can still stick it in the flash message
      flash[:success] = "All instances of '#{@current_tag.name}' have been updated"

      return redirect_to expert_show_tag_path(@replacement_tag.name)
    else

    end
  end

  def delete
    tag = Tag.find(params[:tag_id])
    if !tag.blank?
      affected_objects_hash = tag.tagged_objects_hash
      tag.destroy
      change_hash = Hash.new
      change_hash[:tags] = {:old => tag.name, :new => ""}
      TagEditLog.log_deleted_tags(current_user, change_hash, affected_objects_hash)
      flash[:success] = "The tag '#{tag.name}' has been deleted"
    end
    return redirect_to expert_tags_path
  end

  def delete_unused
    unused_tags_count = 0
    unused_tags = Tag.not_used
    unused_tags_count = unused_tags.length
    unused_tags.destroy_all
    flash[:success] = "#{unused_tags_count} unused tags were deleted"
    return redirect_to expert_tags_path
  end

  def show
    @tag = Tag.find_by_name(params[:name])
    if !@tag
      @tag = Tag.find(params[:name])
    end
    if !@tag
      return redirect_to expert_tags_path()
    end
    if @tag
      @unanswered_questions_count = Question.tagged_with(@tag.id).submitted.not_rejected.count

      @questions = Question.tagged_with(@tag.id).not_rejected.order("questions.created_at DESC").limit(25)
      @question_total_count = Question.tagged_with(@tag.id).order("questions.status_state ASC").count

      @experts = User.tagged_with(@tag.id).order("users.last_active_at DESC").limit(5)
      @expert_total_count = User.tagged_with(@tag.id).count
      @groups = Group.tagged_with(@tag.id).limit(5)
      @group_total_count = Group.tagged_with(@tag.id).count
    else
      @tag = false
      @tag_name = params[:name]
    end
  end

end
