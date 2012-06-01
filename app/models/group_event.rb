class GroupEvent < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :group
  
  # GROUP EVENTS
  GROUP_ACTIVITY = 200
  GROUP_ACTIVITY_START = 201
  GROUP_ACTIVITY_END = 599
  
  GROUP_JOIN = 201
  GROUP_WANTS_TO_JOIN = 202
  GROUP_LEFT= 203
  GROUP_INVITATION= 204
  GROUP_ACCEPT_INVITATION= 205
  GROUP_DECLINE_INVITATION= 206
  GROUP_DONT_WANT_TO_JOIN = 207
  GROUP_INTEREST = 208
  GROUP_NO_INTEREST = 209
  
  GROUP_INVITED_AS_LEADER = 210
  GROUP_INVITED_AS_MEMBER = 211
  GROUP_ADDED_AS_LEADER = 212
  GROUP_ADDED_AS_MEMBER = 213
  GROUP_REMOVED_AS_LEADER = 214
  GROUP_REMOVED_AS_MEMBER = 215
  GROUP_INVITATION_RESCINDED = 216
  
  GROUP_INVITE_REMINDER = 308
  
  GROUP_UPDATE_INFORMATION = 401
  GROUP_CREATED_LIST = 402
  GROUP_TAGGED = 403

  CREATED_GROUP = 110
  LIST_POST = 501
  
  GROUP_EVENT_STRINGS = {
    205 => 'accepted group invitation',
    212 => 'added as group leader',
    213 => 'added as group member',
    402 => 'created group list',
    206 => 'declined group invitation',
    208 => 'indicated interest in group',
    204 => 'group invitation',
    216 => 'group invitation rescinded',
    210 => 'invited group leader',
    211 => 'invited group member',
    308 => 'group invite reminder',
    201 => 'joined group',
    203 => 'left group',
    209 => 'indicated no interest in group',
    207 => 'does not want to join group',
    214 => 'removed as group leader',
    215 => 'removed as group member',
    403 => 'tagged group',
    401 => 'updated group information',
    202 => 'wants to join group',
    110 => 'created group',
    501 => 'posted to list'
  }
  
  
end
