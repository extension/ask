class TinkersToEversToText < ActiveRecord::Migration
  def up
    change_column(:referer_tracks, :landing_page, :text)
  end
end
