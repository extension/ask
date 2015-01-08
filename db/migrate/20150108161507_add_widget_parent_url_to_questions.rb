class AddWidgetParentUrlToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :widget_parent_url, :text
  end
end
