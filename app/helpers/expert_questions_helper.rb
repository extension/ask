module ExpertQuestionsHelper
  def display_handling_rate(ratehash)
    if(ratehash.blank?)
      number_to_percentage(0, :precision => 0).html_safe
    elsif(ratehash[:ratio].blank?)
      number_to_percentage(0, :precision => 0).html_safe
    else
      "#{number_to_percentage(ratehash[:ratio]*100, :precision => 0)} <small>for #{ratehash[:handled]} questions over the last 6 months</small>".html_safe
    end
  end

  def display_handling_rate_bar(ratehash)
    if(ratehash.blank?)
      number_to_percentage(0, :precision => 0).html_safe
    elsif(ratehash[:ratio].blank?)
      number_to_percentage(0, :precision => 0).html_safe
    else
      "<span class=\"handling_rate_graph\">
        <span class=\"graph\" style=\"width: #{ratehash[:ratio] * 100}%;\">
        </span>
      </span>".html_safe
    end
  end

  def display_last_assignment_time(time)
    if(time.blank?)
      'never assigned'
    else
      begin
        time.strftime("%B %e, %Y, %l:%M %p %Z")
      rescue
        'unknown'
      end
    end
  end
end
