require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'ember/eruby_delimited_directive_test'
require 'ember/eruby_shorthand_directive_test'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_directive"

D ERubyDirective do
  D.< do
    @parser = ERubyDirectiveParser.new
  end

  S ERubyDelimitedDirective
  S ERubyShorthandDirective
end
