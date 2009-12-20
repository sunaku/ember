require 'test_helper'
require 'ember/eruby_delimited_directive_parser'

D ERubyDelimitedDirective do
  D.< do
    @parser = ERubyDelimitedDirectiveParser.new
  end

  S! ERubyDelimitedDirective do
    extend WhitespaceHelper

    D 'empty input' do
      F @parser.parse('')
    end

    D 'empty directives' do
      T @parser.parse('<%%>')
      F @parser.parse('<%%%>')
      F @parser.parse('<%% %>')
      F @parser.parse('<% %%>')
      F @parser.parse('<%%%%>')
    end

    D 'blank directives' do
      each_whitespace do |whitespace|
        T @parser.parse("<%#{whitespace}%>")
        F @parser.parse("<%#{whitespace}%%>")
        F @parser.parse("<%%#{whitespace}%>")
        F @parser.parse("<%%#{whitespace}%%>")

        next if whitespace.empty?
        T @parser.parse("<%#{whitespace}%#{whitespace}%>")
        T @parser.parse("<%#{whitespace}%%#{whitespace}%>")
      end
    end

    D 'non-blank directives' do
      T @parser.parse("<%hello%>")
      T @parser.parse("<% hello%>")
      T @parser.parse("<%hello %>")
      T @parser.parse("<% hello %>")
    end

    D 'nested directives' do
      F @parser.parse("<% inner %> outer %>")
      T @parser.parse("<% inner %%> outer %>")

      F @parser.parse("<% outer <% inner %>")
      T @parser.parse("<% outer <%% inner %>")

      F @parser.parse("<% outer <% inner %> outer %>")
      T @parser.parse("<% outer <%% inner %%> outer %>")

      F @parser.parse("<% outer <% inner <% atomic %> inner %> outer %>")
      T @parser.parse("<% outer <%% inner <%% atomic %%> inner %%> outer %>")
    end
  end
end
