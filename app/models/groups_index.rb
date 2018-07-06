# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file


class GroupsIndex < Chewy::Index
  settings analysis: {
    tokenizer: {
      autocomplete: {
        type: "edge_ngram",
        min_gram: 2,
        max_gram: 10,
        token_chars: [
          "letter",
          "digit"
        ]
      }
    },
    analyzer: {
      autocomplete: {
        tokenizer: 'autocomplete',
        filter: ['lowercase']
      }
    }
  }

  define_type Group do
    field :name, type: 'text', analyzer: 'autocomplete', search_analyzer: 'standard'
    field :description, type: 'text'
    field :group_active, type: 'boolean'
  end

  def self.active_groups
    query(match: {group_active: true})
  end

  def self.name_search(searchquery)
    query(match: {name: searchquery})
  end

  def self.fulltextsearch(searchquery)
    query(
      multi_match: {
        query: searchquery,
        fields: [:name,:description]
      }
    )
  end

end
