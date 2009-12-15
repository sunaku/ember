require File.dirname(__FILE__) + '/../helper.rb'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_delimited_directive"

test ERubyDelimitedDirective do
  prepare do
    @parser = ERubyDelimitedDirectiveParser.new
  end

  share! ERubyDelimitedDirective do
    extend WhitespaceHelper

    test 'empty input' do
      deny @parser.parse('')
    end

    test 'empty directives' do
      aver @parser.parse('<%%>')
      deny @parser.parse('<%%%>')
      deny @parser.parse('<%% %>')
      deny @parser.parse('<% %%>')
      deny @parser.parse('<%%%%>')
    end

    test 'blank directives' do
      each_whitespace do |whitespace|
        aver @parser.parse("<%#{whitespace}%>")
        deny @parser.parse("<%#{whitespace}%%>")
        deny @parser.parse("<%%#{whitespace}%>")
        deny @parser.parse("<%%#{whitespace}%%>")

        next if whitespace.empty?
        aver @parser.parse("<%#{whitespace}%#{whitespace}%>")
        aver @parser.parse("<%#{whitespace}%%#{whitespace}%>")
      end
    end

    test 'non-blank directives' do
      aver @parser.parse("<%hello%>")
      aver @parser.parse("<% hello%>")
      aver @parser.parse("<%hello %>")
      aver @parser.parse("<% hello %>")
    end

    test 'nested directives' do
      deny @parser.parse("<% inner %> outer %>")
      aver @parser.parse("<% inner %%> outer %>")

      deny @parser.parse("<% outer <% inner %>")
      aver @parser.parse("<% outer <%% inner %>")

      deny @parser.parse("<% outer <% inner %> outer %>")
      aver @parser.parse("<% outer <%% inner %%> outer %>")

      deny @parser.parse("<% outer <% inner <% atomic %> inner %> outer %>")
      aver @parser.parse("<% outer <%% inner <%% atomic %%> inner %%> outer %>")
    end
  end
end
