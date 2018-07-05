# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file


class UsersIndex < Chewy::Index
  settings analysis: {
    analyzer: {
      substringsearch: {
        tokenizer: 'keyword',
        filter: ['lowercase']
      }
    }
  }

  define_type User.exid_holder do
    field :name, type: 'text', analyzer: 'substringsearch'
    field :login, type: 'text', analyzer: 'substringsearch'
    field :email, type: 'text', analyzer: 'substringsearch'
    field :bio, type: 'text'
    field :tag_fulltext, type: 'text'
    field :unavailable, type: 'boolean'
    field :kind, type: 'text'
    field :last_activity_at, type: 'date'
  end

end
