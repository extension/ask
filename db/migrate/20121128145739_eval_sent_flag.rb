class EvalSentFlag < ActiveRecord::Migration
  def change
    add_column('questions','evaluation_sent',:boolean,default: false)
    add_index('questions',['evaluation_sent'],name: 'evaluation_flag_ndx')
    execute "UPDATE questions SET evaluation_sent = 0 WHERE 1"
  end

end
