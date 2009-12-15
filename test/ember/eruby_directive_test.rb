require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'ember/eruby_delimited_directive_test'
require 'ember/eruby_shorthand_directive_test'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_directive"

test ERubyDirective do
  prepare do
    @parser = ERubyDirectiveParser.new
  end

  share ERubyDelimitedDirective
  share ERubyShorthandDirective
end
