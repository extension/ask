# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

module MarkupScrubber
  def self.included(base)
    base.extend(self)
  end

  def scrub_and_sanitize(html_string)
    # make valid html if we don't have it - not sure if this
    # may ever throw an exception, if it does, I probably
    # want to know what caused it, so not catching for now
    valid_html = Nokogiri::HTML::DocumentFragment.parse(html_string).to_html

    # scrub with Loofah prune in order to strip unknown and "unsafe" tags
    # http://loofah.rubyforge.org/loofah/classes/Loofah/Scrubbers/Prune.html#M000036
    scrubbed_html = Loofah.scrub_fragment(valid_html, :prune).to_s

    # use ActionController sanitize to sanitize the Loofah scrubbed html
    # see: ActionView::Base.sanitized_allowed_tags for the list of allowed tags
    sanitized_html =  ActionController::Base.helpers.sanitize(scrubbed_html)

    # return the sanitized_html
    sanitized_html
  end

  def html_to_text(html_string)
    parsed_html = Nokogiri::HTML::DocumentFragment.parse(html_string)
    # text markup (via: http://stackoverflow.com/questions/10144739/convert-html-to-plain-text-with-inclusion-of-brs)

    blocks = %w[p div address]                      # els to put newlines after
    swaps  = { "br"=>"\n", "hr"=>"\n#{'-'*70}\n" }  # content to swap out

    # Get rid of superfluous whitespace in the source
    parsed_html.xpath('.//text()').each{ |t| t.content=t.text.gsub(/\s+/,' ') }

    # Swap out the swaps
    parsed_html.css(swaps.keys.join(',')).each{ |n| n.replace( swaps[n.name] ) }

    # Slap a couple newlines after each block level element
    parsed_html.css(blocks.join(',')).each{ |n| n.after("\n\n") }

    # Return the modified text content
    parsed_html.text
  end
end