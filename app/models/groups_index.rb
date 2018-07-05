# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file


class GroupsIndex < Chewy::Index
  settings analysis: {
    analyzer: {
      substringsearch: {
        tokenizer: 'keyword',
        filter: ['lowercase']
      }
    }
  }

  define_type Group do
    field :name, type: 'text', analyzer: 'substringsearch'
    field :description, type: 'text'
    field :group_active, type: 'boolean'
  end
end
