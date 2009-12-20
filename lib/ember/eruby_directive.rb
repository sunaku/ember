require 'ember/eruby_delimited_directive'
require 'ember/eruby_shorthand_directive'

require 'treetop'
Treetop.load __FILE__.sub(/rb$/, 'treetop')

module ERubyDirective
  def comment?
    text_value =~ /\A#/
  end

  def assign?
    text_value =~ /\A=/
  end
end
