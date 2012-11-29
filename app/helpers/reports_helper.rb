# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

module ReportsHelper

  def pct_change(change,extraclass=nil)
    if(!change)
      'n/a'
    else
      classes = []
      classes << sign_class_percentage(change)
      if(extraclass)
        classes << extraclass
      end
      "<span class='#{classes.join(' ')}'>#{number_to_percentage(change * 100, :precision => 2)}</span>".html_safe
    end
  end


end
