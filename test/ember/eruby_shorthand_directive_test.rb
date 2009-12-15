require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_shorthand_directive"

test ERubyShorthandDirective do
  prepare do
    @parser = ERubyShorthandDirectiveParser.new
  end

  share! ERubyShorthandDirective do
    extend WhitespaceHelper

    test 'empty input' do
      deny @parser.parse('')
    end

    test 'empty directives' do
      aver @parser.parse('%')
      deny @parser.parse('%%')
    end

    test 'blank directives' do
      each_whitespace do |whitespace|
        aver @parser.parse("%#{whitespace}")
        deny @parser.parse("%%#{whitespace}")

        next if whitespace.empty?
        aver @parser.parse("%#{whitespace}%")
        aver @parser.parse("%#{whitespace}%%")
      end
    end

    test 'non-blank directives' do
      aver @parser.parse("%hello")
      aver @parser.parse("% hello")
      aver @parser.parse("%hello ")
      aver @parser.parse("% hello ")
    end
  end
end
