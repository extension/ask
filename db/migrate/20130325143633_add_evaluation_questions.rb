# encoding: UTF-8

class AddEvaluationQuestions < ActiveRecord::Migration
  def up
    # cleanup
    remove_column('evaluation_questions','creator_id')
    remove_column('evaluation_answers','responsetype')

    # duplicate
    execute("CREATE TABLE old_evaluation_answers LIKE evaluation_answers;")
    execute("INSERT INTO old_evaluation_answers SELECT * FROM evaluation_answers;")

    # truncate
    execute("TRUNCATE table evaluation_answers;")

    current_days_question = EvaluationQuestion.find(6)
    current_days_question.update_column(:is_active,false)

    # fixes
    fix_one = EvaluationQuestion.find(1)
    fix_one.update_attributes({responses: ['a personal curiosity that was not too important','critically important to me']})

    fix_four = EvaluationQuestion.find(4)
    fix_four.update_attributes({responses: ['little economic consequence to me','significant economic concern to me']})


    EvaluationQuestion.create(prompt: "My expectation for the time it would take for me to receive a response to my question was (in days):",
                              responsetype: EvaluationQuestion::MULTIPLE_CHOICE,
                              questionorder: 6,
                              responses: ['Less than 1 day',
                                          '1 to 2 days',
                                          '2 to 3 days',
                                          '3 to 4 days',
                                          '4 to 5 days',
                                          'no expectation'])

    EvaluationQuestion.create(prompt: "To what extent have you changed a practice or behavior based on the answer you received?",
                              responsetype: EvaluationQuestion::MULTIPLE_CHOICE,
                              questionorder: 7,
                              responses: ['No extent, I have not changed a practice or behavior',
                                          'Some extent, I’m considering changing a practice or behavior',
                                          'Moderate extent, I’m in the planning stages for changing a practice or behavior',
                                          'Great extent, I have changed a practice or behavior'])

    EvaluationQuestion.create(prompt: "How familiar were you with Cooperative Extension before you submitted your question?",
                              responsetype: EvaluationQuestion::MULTIPLE_CHOICE,
                              questionorder: 8,
                              responses: ['I had never heard of Cooperative Extension',
                                          'I was aware of Cooperative Extension but had never used it',
                                          'I had occasionally used the services of Cooperative Extension',
                                          'I was a frequent user of Cooperative Extension'])

    EvaluationQuestion.create(prompt: "How did your experience in using Ask an Expert make you feel?",
                              responsetype: EvaluationQuestion::MULTIPLE_CHOICE,
                              questionorder: 9,
                              responses: ['Totally disappointed',
                                          'Disappointed',
                                          'Neither disappointed nor satisfied',
                                          'Satisfied',
                                          'Completely Satisfied'])
    EvaluationQuestion.create(prompt: "Is there anything else about your experience in using Ask an Expert you would like to tell us?",
                              responsetype: EvaluationQuestion::TEXT,
                              questionorder: 10)
  end

end
