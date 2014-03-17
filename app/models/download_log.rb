# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class DownloadLog < ActiveRecord::Base
  serialize :notifylist
  attr_accessible :download, :download_id, :downloaded_by, :downloader

  belongs_to :download
  belongs_to :downloader, class: 'User', foreign_key: 'downloaded_by'

end
