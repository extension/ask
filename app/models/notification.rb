class Notification < ActiveRecord::Base
  belongs_to :notifiable, :polymorphic => true
  serialize :additional_data
  
  ###############################
  #  Group Notifications
  
  NOTIFICATION_GROUP = [100,999]   # 'group notifications in this range'
  
  GROUP_USER_JOIN = 101
  GROUP_USER_WANTSTOJOIN = 102
  GROUP_USER_LEFT= 103
  GROUP_USER_ACCEPT_INVITATION= 104
  GROUP_USER_DECLINE_INVITATION= 105
  GROUP_USER_NOWANTSTOJOIN= 106
  GROUP_USER_INTEREST = 107
  GROUP_USER_NOINTEREST = 108

  GROUP_LEADER_INVITELEADER = 201
  GROUP_LEADER_INVITEMEMBER = 202
  GROUP_LEADER_RESCINDINVITATION = 203
  GROUP_LEADER_INVITEREMINDER = 204
  GROUP_LEADER_ADDLEADER = 301
  GROUP_LEADER_ADDMEMBER = 302
  GROUP_LEADER_REMOVELEADER = 401
  GROUP_LEADER_REMOVEMEMBER = 402

  ##########################################
  #  Ask an Expert Notifications - Internal

  NOTIFICATION_AAE_INTERNAL = [1000,1999]   # 'aae-internal'
  AAE_ASSIGNMENT = 1001  # assignment notification
  AAE_REASSIGNMENT = 1002  # reassignment notification
  AAE_ESCALATION = 1003  # escalation notification
  AAE_PUBLIC_EDIT = 1004  # a public user edited their question
  AAE_PUBLIC_COMMENT = 1005 # a public user posted another comment
  AAE_REJECT = 1006 # an expert has rejected a question
  AAE_VACATION_RESPONSE = 1007 # received a vacation response to an assigned question
  AAE_EXPERT_COMMENT = 1008 # an expert posted a comment
  AAE_EXPERT_NOREPLY = 1009 # an expert replied to the no-reply address
  AAE_WIDGET_BROADCAST = 1010 # broadcast email sent to all widget assignees 
    
  ##########################################
  #  Ask an Expert Notifications - Public
  
  NOTIFICATION_AAE_PUBLIC = [2000,2099]   # 'aae-public'
  AAE_PUBLIC_EXPERT_RESPONSE = 2001  # notification of an expert response, also "A Space Odyssey"
  AAE_PUBLIC_NOREPLY = 2002 # public replied to the no-reply address
  AAE_PUBLIC_NOQUESTION = 2003 # public sent a new question to the no-reply address
  AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT = 2010  # notification of submission, also "The Year We Make Contact"

  ##########################################
end
