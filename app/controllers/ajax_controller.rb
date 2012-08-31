# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AjaxController < ApplicationController
  def tags
    if params[:term]
      search_term = params[:term].gsub('%', '') #TODO figure out why params[:term] appends a "%" sign
      tags = Tag.where("name like '%#{params[:term]}%'").limit(12)
    else
      tags = Tag.order('created_at DESC').limit(12)
    end
    list = []
    tags.each do |t|
      list <<  Hash[ id: t.id, label: t.name, name: t.name] if t.name != search_term
    end
    list.unshift(Hash[id: nil, label: search_term, name: search_term])
    render json: list
  end
end
