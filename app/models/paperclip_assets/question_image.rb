class Question::Image < Asset
  has_attached_file :attachment, 
                    :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension",
                    :styles => Proc.new { |attachment| attachment.instance.styles }
                      attr_accessible :attachment
  # http://www.ryanalynporter.com/2012/06/07/resizing-thumbnails-on-demand-with-paperclip-and-rails/
  def dynamic_style_format_symbol
      URI.escape(@dynamic_style_format).to_sym
    end

    def styles
      unless @dynamic_style_format.blank?
        { dynamic_style_format_symbol => @dynamic_style_format }
      else
        { :medium => "300x300>", :thumb => "100x100>" }
      end
    end

    def dynamic_attachment_url(format)
      @dynamic_style_format = format
      attachment.reprocess!(dynamic_style_format_symbol) unless attachment.exists?(dynamic_style_format_symbol)
      attachment.url(dynamic_style_format_symbol)
    end
end