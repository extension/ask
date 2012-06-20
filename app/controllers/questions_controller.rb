class QuestionsController < ApplicationController
  layout 'public'
  
  def show
    @question = Question.find_by_id(params[:id])
    
    if @question.is_private?
      redirect_to home_private_page_url
    end
    
    @question_responses = @question.responses
    @fake_related = Question.public_visible.find(:all, :limit => 3, :offset => rand(Question.count))
  end
end
