# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

module MarkupScrubber
  def self.included(base)
    base.extend(self)
  end

  def cleanup_html(html_string)
    # scrub with Loofah prune in order to strip unknown and "unsafe" tags
    # http://rubydoc.info/github/flavorjones/loofah/master/Loofah/Scrubbers/Prune

    # this should be the list of allowed tags:
    # https://github.com/flavorjones/loofah/blob/master/lib/loofah/html5/whitelist.rb
    Loofah.scrub_fragment(html_string, :prune).to_s
  end

  def html_to_text(html_string)
    Loofah.fragment(html_string).text
  end

  # adds some cleverness with regard to whitespace and block elements
  # http://rubydoc.info/github/flavorjones/loofah/master/Loofah/TextBehavior#to_text-instance_method
  def html_to_pretty_text(html_string)
    Loofah.fragment(html_string).to_text
  end


end