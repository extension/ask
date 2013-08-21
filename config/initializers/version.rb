class Version < ActiveRecord::Base
  attr_accessible :ip_address, :reason, :notify_submitter
end