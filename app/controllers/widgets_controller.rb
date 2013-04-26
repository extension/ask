class WidgetsController < ApplicationController
  
  def front_porch
    @question_list = Array.new
    group_array = Array.new
    
    @title = "eXtension Latest Resolved Questions"
    @path_to_questions = root_path
    questions = Question.public_visible_answered.featured.order('featured_at DESC')
    
    if params[:limit].blank? || params[:limit].to_i <= 0
      question_limit = 5
    else
      question_limit = params[:limit].to_i
    end
    
    if params[:width].blank? || params[:width].to_i <= 0
      @width = 300
    else
      @width = params[:width].to_i
    end
    
    if questions.length == 0
      @question_list = []
    else
      questions.each do |q|
        assigned_group = q.assigned_group
        @question_list << q if (!group_array.include?(assigned_group.id) || assigned_group.blank?)
        break if (@question_list == question_limit || @question_list.length == questions.length)
        if assigned_group.present? 
          group_array << assigned_group.id
        end
      end
    end
  end
  
end
