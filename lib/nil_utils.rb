# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

module NilUtils

  def quoted_value_or_null(value)
    value.blank? ? 'NULL' : ActiveRecord::Base.quote_value(value)
  end

  def value_or_null(value)
    value.blank? ? 'NULL' : value
  end

  def name_or_null(item)
    item.nil? ? 'NULL' : ActiveRecord::Base.quote_value(item.name)
  end

  def name_or_nil(item)
    item.nil? ? nil : item.name
  end

end
