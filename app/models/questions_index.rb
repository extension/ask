# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file


class QuestionsIndex < Chewy::Index
  # status numbers (for status_state)  - not, MUST MATCH Question
  STATUS_SUBMITTED = 1
  STATUS_RESOLVED = 2
  STATUS_NO_ANSWER = 3
  STATUS_REJECTED = 4
  STATUS_CLOSED = 5

  define_type Question do
    field :title, type: 'text', term_vector: 'yes'
    field :body, type: 'text', term_vector: 'yes'
    field :response_list, type: 'text', term_vector: 'yes'
    field :status_state, type: 'integer'
    field :is_private, type: 'boolean'
  end

  def self.public_questions
    query(match: {is_private: false})
  end

  def self.not_rejected
    query(
      bool: {
        must_not: {
          term: {
            status_state: STATUS_REJECTED
          }
        }
      }
    )
  end

  def self.fulltextsearch(searchquery)
    query(
      multi_match: {
        query: searchquery,
        fields: [:title,:body,:response_list]
      }
    )
  end

  def self.similar_to_question(question)
    query(
      more_like_this: {
          fields: [
            :title,
            :body,
            :response_list
          ],
          like: [
            {
              "_index" => self.index_name,
              "_type" => QuestionsIndex::Question.type_name,
              "_id" => "#{question.id}"
            }
          ],
          min_term_freq: 2,
          max_query_terms: 25
        }
    ).order("_score")
  end

end
