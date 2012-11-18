class AddEvaluation < ActiveRecord::Migration
  def change

    # evaluation questions and answers
    create_table "evaluation_questions", :force => true do |t|
      t.boolean  "is_active", default: true
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
      t.string   "responsetype"
      t.text     "response"
      t.integer  "value"
      t.timestamps
    end

    add_index "evaluation_answers", ["evaluation_question_id", "user_id", "question_id"], :name => "eq_u_q_ndx", :unique => true

    create_table "evaluation_logs", :force => true do |t|
      t.integer  "evaluation_answer_id", :null => false
      t.text     "changed_answers"
      t.datetime "created_at"
    end

    add_index "evaluation_logs", ["evaluation_answer_id"], :name => "log_ndx"

    EvaluationQuestion.reset_column_information

    EvaluationQuestion.create(prompt: "The question you asked was...",
                              responsetype: EvaluationQuestion::SCALE,
                              questionorder: 1,
                              responses: ['a personal curiousity that was not too important','critically important to me'],
                              range_start: 1,
                              range_end: 5,
                              creator_id: User.system_user_id)

    EvaluationQuestion.create(prompt: "The response given by the Ask an Expert service to my question...",
                              responsetype: EvaluationQuestion::SCALE,
                              questionorder: 2,
                              responses: ['did not answer my question(s)','completely answered my question(s)'],
                              range_start: 1,
                              range_end: 5,
                              creator_id: User.system_user_id)

    EvaluationQuestion.create(prompt: "The advice that was offered was...",
                              responsetype: EvaluationQuestion::SCALE,
                              questionorder: 3,
                              responses: ['too complex','too simplistic'],
                              range_start: 1,
                              range_end: 5,
                              creator_id: User.system_user_id)

    EvaluationQuestion.create(prompt: "In this story, the need for an answer was of...",
                              responsetype: EvaluationQuestion::SCALE,
                              questionorder: 4,
                              responses: ['little economic consequence to me','of significant economic concern to me'],
                              range_start: 1,
                              range_end: 5,
                              creator_id: User.system_user_id)

    EvaluationQuestion.create(prompt: "If the answer had an economic benefit to you, what would you estimate that benefit to be in U.S. dollars?",
                              responsetype: EvaluationQuestion::OPEN_DOLLAR_VALUE,
                              questionorder: 5,
                              creator_id: User.system_user_id)

    EvaluationQuestion.create(prompt: "My expectation for the time it would take for me to receive a  response to my question was:",
                              responsetype: EvaluationQuestion::OPEN_TIME_VALUE,
                              questionorder: 6,
                              creator_id: User.system_user_id)



    create_table "demographic_questions", :force => true do |t|
      t.boolean  "is_active", default: true
      t.text     "prompt"
      t.integer  "questionorder"
      t.string   "responsetype"
      t.text     "responses"
      t.integer  "range_start"
      t.integer  "range_end"
      t.integer  "creator_id"
      t.timestamps
    end


    create_table "demographics", :force => true do |t|
      t.integer  "demographic_question_id", :null => false
      t.integer  "user_id",  :null => false
      t.text     "response"
      t.integer  "value"
      t.timestamps
    end

    add_index "demographics", ["demographic_question_id", "user_id"], :name => "dq_u_ndx", :unique => true

    create_table "demographic_logs", :force => true do |t|
      t.integer  "demographic_id", :null => false
      t.text     "changed_answers"
      t.datetime "created_at"
    end

    add_index "demographic_logs", ["demographic_id"], :name => "log_ndx"


    # demographic questions
    DemographicQuestion.reset_column_information

    DemographicQuestion.create(prompt: "Your gender:",
                               responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                               questionorder: 1,
                               responses: ['Female','Male'],
                               creator_id: User.system_user_id)

    DemographicQuestion.create(prompt: "Your age:",
                               responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                               questionorder: 2,
                               responses: ['18-29','30-49','50-64','65+'],
                               creator_id: User.system_user_id)

    DemographicQuestion.create(prompt: "Which of the following best describes your formal education:",
                               responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                               questionorder: 3,
                               responses: ['Less than high school','High school graduate/GED','Some college','College graduate','Master degree','Doctorate/Law degree'],
                               creator_id: User.system_user_id)

    DemographicQuestion.create(prompt: "Your yearly family income is:",
                               responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                               questionorder: 4,
                               responses: ['Less than $25K','$25K - $49K','$50K - $74K','$75K - $99K','Greater than $100K','Decline to answer'],
                               creator_id: User.system_user_id)

    DemographicQuestion.create(prompt: "Are you of Hispanic, Latino or Spanish origin?",
                               responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                               questionorder: 5,
                               responses: ['yes, Mexican, Mexican American, Chicano','yes, Puerto Rican','yes, Cuban','no, not Hispanic, Latino, or Spanish origin','don\'t know'],
                               creator_id: User.system_user_id)

    DemographicQuestion.create(prompt: "What race do you consider yourself to be?",
                               responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                               questionorder: 6,
                               responses: ['White','Black/African American','American Indian or Alaska Native','Asian Indian',
                                           'Chinese','Japanese','Filipino','Korean','Vietnamese','Some other Asian','Native Hawaiian',
                                           'Samoan','Guamanian or Chamorro','some other Pacific Islander','other race','don\'t know'],
                               creator_id: User.system_user_id)


  end

end
