require 'test_helper'
require 'ember/eruby_shorthand_directive'

D ERubyShorthandDirective do
  D.< do
    @parser = ERubyShorthandDirectiveParser.new
  end

  S! ERubyShorthandDirective do
    extend WhitespaceHelper

    D 'empty input' do
      F @parser.parse('')
    end

    D 'empty directives' do
      T @parser.parse('%')
      F @parser.parse('%%')
    end

    D 'blank directives' do
      each_whitespace do |whitespace|
        T @parser.parse("%#{whitespace}")
        F @parser.parse("%%#{whitespace}")

        next if whitespace.empty?
        T @parser.parse("%#{whitespace}%")
        T @parser.parse("%#{whitespace}%%")
      end
    end

    D 'non-blank directives' do
      T @parser.parse("%hello")
      T @parser.parse("% hello")
      T @parser.parse("%hello ")
      T @parser.parse("% hello ")
    end
  end
end
