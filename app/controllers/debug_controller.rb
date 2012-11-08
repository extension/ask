# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DebugController < ApplicationController
  skip_before_filter :set_yolo, only: [:session_information]
  before_filter :require_exid, only: [:signatures]


  def session_information
    set_yolo if(!params[:skip_set_yolo])
  end

  def signatures
    @userlist = User.where("length(signature) > 0").where("signature != CONCAT('-',first_name,' ',last_name)").order("length(signature) DESC").page(params[:page]).per(100)
  end

  def cmb_signatures
    cmb_list_20121108 = [240, 21, 99, 254, 24, 148, 252, 37, 245, 79, 124, 76, 167, 3177, 3149, 3072, 285, 213, 227, 46,
                         2259, 2853, 7376, 7687, 4563, 7039, 5921, 3381, 7648, 23, 4720, 91, 221, 3476, 343, 8773, 51, 3639,
                         8752, 1425, 9485, 137, 487, 8686, 10444, 2131, 18, 4008, 8499, 8813, 1649, 6361, 8820, 9043, 88, 14987,
                         29, 7702, 15291, 15159, 157, 3227, 7243, 9299, 6731, 13108, 10836, 14337, 7079, 4664, 1395, 128781, 15285,
                         129382, 3315, 8622, 7175, 122796, 142814, 3172, 14552, 133506, 10456, 111606, 532, 14664, 15864, 12163, 790,
                         302, 11911, 8199, 14003, 5122, 136583, 12405]

    @userlist = User.where("id in (#{cmb_list_20121108.join(',')})").where("length(signature) > 0").where("signature != CONCAT('-',first_name,' ',last_name)").order("length(signature) DESC").page(params[:page]).per(100)
    render 'signatures'
  end

end