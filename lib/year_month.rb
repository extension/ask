# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

module YearMonth


  def year_months_between_dates(start_date,end_date)
    year_months = []
    # construct a set of year-months given the start and end dates
    the_end = end_date.beginning_of_month
    loop_date = start_date.beginning_of_month
    while loop_date <= the_end
      year_months << "#{loop_date.year}-" + "%02d" % loop_date.month
      loop_date = loop_date.next_month
    end
    year_months
  end


end