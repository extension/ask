class AddEvaluation < ActiveRecord::Migration
  def change

    # evaluation questions and answers
    create_table "evaluation_questions", :force => true do |t|
      t.boolean  "is_active"
      t.text     "prompt"
      t.text     "secondary_prompt"
      t.integer  "questionorder"
      t.string   "responsetype"
      t.text     "responses"
      t.integer  "range_start"
      t.integer  "range_end"
      t.integer  "creator_id"
      t.timestamps
    end

    create_table "demographic_questions", :force => true do |t|
      t.boolean  "is_active"
      t.text     "prompt"
      t.integer  "questionorder"
      t.string   "responsetype"
      t.text     "responses"
      t.integer  "range_start"
      t.integer  "range_end"
      t.integer  "creator_id"
      t.timestamps
    end


    create_table "evaluation_answers", :force => true do |t|
      t.integer  "evaluation_question_id", :null => false
      t.integer  "user_id",  :null => false
      t.integer  "question_id",  :null => false
      t.text     "response"
      t.text     "secondary_response"
      t.integer  "value"
      t.timestamps
    end

    add_index "evaluation_answers", ["evaluation_question_id", "user_id", "question_id"], :name => "eq_u_q_ndx", :unique => true

    create_table "demographics", :force => true do |t|
      t.integer  "demographic_question_id", :null => false
      t.integer  "user_id",  :null => false
      t.text     "response"
      t.integer  "value"
      t.text     "changelog"
      t.timestamps
    end

    add_index "demographics", ["demographic_question_id", "user_id"], :name => "dq_u_ndx", :unique => true

    create_table "demographic_logs", :force => true do |t|
      t.integer  "demographic_question_id", :null => false
      t.integer  "user_id",  :null => false
      t.text     "response"
      t.integer  "value"
      t.text     "changelog"
      t.timestamps
    end



    EvaluationQuestion.create(conference: nexc2012,
                              prompt: "How would you rate the usefulness of this presentation to your daily work?",
                              responsetype: EvaluationQuestion::MULTIPLE_CHOICE,
                              questionorder: 1,
                              responses: ['Very useful','Somewhat useful','Of very little use','Not at all useful'],
                              creator: Learner.learnbot)



  end

end
