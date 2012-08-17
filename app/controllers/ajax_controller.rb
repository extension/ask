# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AjaxController < ApplicationController
  def tags
    if params[:term]
      like= "%".concat(params[:term].concat("%"))
      tags = Tag.where("name like ?", like).limit(15)
    else
      tags = Tag.order('created_at DESC').limit(15)
    end
    list = tags.map {|t| Hash[ id: t.id, label: t.name, name: t.name]}
    render json: list
  end
end
