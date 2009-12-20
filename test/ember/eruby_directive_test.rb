require 'test_helper'
require 'ember/eruby_directive_parser'
require 'ember/eruby_delimited_directive_test'
require 'ember/eruby_shorthand_directive_test'

D ERubyDirective do
  D.< do
    @parser = ERubyDirectiveParser.new
  end

  S ERubyDelimitedDirective
  S ERubyShorthandDirective
end
