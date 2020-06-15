# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class EvaluationController < ApplicationController
  before_filter :signin_required, only: [:example]
  before_filter :set_format, :only => [:view]

  def notice
    @page_title = 'Evaluation Questions Have Been Discontinued'
  end

end
