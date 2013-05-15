class WidgetLog < ActiveRecord::Base
  KNOWN_PARAMS = ['limit', 'width', 'tags', 'group_id', 'operator']
end
