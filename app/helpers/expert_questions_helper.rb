module ExpertQuestionsHelper
  def display_handling_rate(ratehash)
    if(ratehash.blank?)
      number_to_percentage(0, :precision => 0).html_safe
    elsif(ratehash[:ratio].blank?)
      number_to_percentage(0, :precision => 0).html_safe
    else
      number_to_percentage(ratehash[:ratio]*100, :precision => 0).html_safe
    end
  end
end