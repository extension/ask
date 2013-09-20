class FixEducationDemographic < ActiveRecord::Migration
  def up

    education_demographic = DemographicQuestion.find(3)
    education_demographic.update_attributes({:responses => ['Less than high school','High school graduate/GED','Some college','College graduate','Master\'s degree','Doctorate/Law degree']})

    replacement = ActiveRecord::Base.quote_value("Master's Degree")
    execute("UPDATE demographics SET response = #{replacement} WHERE response = 'Master Degree'")
  end
end
