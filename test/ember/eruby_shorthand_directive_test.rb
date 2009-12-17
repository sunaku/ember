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
      each_space do |space|
        T @parser.parse("%#{space}")
        F @parser.parse("%%#{space}")

        next if space.empty?
        T @parser.parse("%#{space}%")
        T @parser.parse("%#{space}%%")
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
