# this is almost easter egg like
# in that we have text and html
# that gets stored in our question/response bodies
# and running simple_format on html is just
# insane, but fairly necessary for the text
# hence, the alias
module ActionView
  module Helpers
    module TextHelper
      alias :simple_insanity :simple_format
    end
  end
end
