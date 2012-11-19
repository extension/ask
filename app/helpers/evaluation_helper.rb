# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

module EvaluationHelper

  def is_multichoice_demographic_checked_for_user?(user,demographic_question,response)
    if(!user)
      false
    else
      answer = demographic_question.answer_for_user(user)
      if(!answer)
        false
      elsif(answer.response == response)
        true
      else
        false
      end
    end
  end


  def scale_value_for_evalquestion_question_user(evaluation_question,question,user)
    evaluation_question.answer_value_for_user_and_question(user,question) || 3
  end

  def open_value_for_evalquestion_question_user(evaluation_question,question,user)
    evaluation_question.answer_value_for_user_and_question(user,question) || ''
  end
end