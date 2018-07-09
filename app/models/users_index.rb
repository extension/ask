# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file


class UsersIndex < Chewy::Index
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

  define_type User.exid_holder do
    field :name, type: 'text', analyzer: 'autocomplete', search_analyzer: 'standard'
    field :login, type: 'text', analyzer: 'autocomplete', search_analyzer: 'standard'
    field :email, type: 'text', analyzer: 'autocomplete', search_analyzer: 'standard'
    field :bio, type: 'text'
    field :unavailable, type: 'boolean'
    field :last_activity_at, type: 'date'
  end


  def self.available
    query(match: {unavailable: false})
  end

  def self.name_or_login_search(searchquery)
    query(
      multi_match: {
        query: searchquery,
        fields: [:name,:login]
      }
    )
  end

  def self.fulltextsearch(searchquery)
    query(
      multi_match: {
        query: searchquery,
        fields: [:name,:login,:bio]
      }
    )
  end

end
