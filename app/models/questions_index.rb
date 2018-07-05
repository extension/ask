# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file


class QuestionsIndex < Chewy::Index
  define_type Question do
    field :title, type: 'text', term_vector: 'yes'
    field :body, type: 'text', term_vector: 'yes'
    field :response_list, type: 'text', term_vector: 'yes'
    field :status_state, type: 'integer'
    field :is_private, type: 'boolean'
  end
end
