require File.dirname(__FILE__) + '/../helper.rb'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_delimited_directive"

describe ERubyDelimitedDirective do
  setup do
    @parser = ERubyDelimitedDirectiveParser.new
  end

  share! ERubyDelimitedDirective do
    extend WhitespaceHelper

    context 'empty input' do
      refute @parser.parse('')
    end

    context 'empty directives' do
      assert @parser.parse('<%%>')
      refute @parser.parse('<%%%>')
      refute @parser.parse('<%% %>')
      refute @parser.parse('<% %%>')
      refute @parser.parse('<%%%%>')
    end

    context 'blank directives' do
      each_whitespace do |whitespace|
        assert @parser.parse("<%#{whitespace}%>")
        refute @parser.parse("<%#{whitespace}%%>")
        refute @parser.parse("<%%#{whitespace}%>")
        refute @parser.parse("<%%#{whitespace}%%>")

        next if whitespace.empty?
        assert @parser.parse("<%#{whitespace}%#{whitespace}%>")
        assert @parser.parse("<%#{whitespace}%%#{whitespace}%>")
      end
    end

    context 'non-blank directives' do
      assert @parser.parse("<%hello%>")
      assert @parser.parse("<% hello%>")
      assert @parser.parse("<%hello %>")
      assert @parser.parse("<% hello %>")
    end

    context 'nested directives' do
      refute @parser.parse("<% inner %> outer %>")
      assert @parser.parse("<% inner %%> outer %>")

      refute @parser.parse("<% outer <% inner %>")
      assert @parser.parse("<% outer <%% inner %>")

      refute @parser.parse("<% outer <% inner %> outer %>")
      assert @parser.parse("<% outer <%% inner %%> outer %>")

      refute @parser.parse("<% outer <% inner <% atomic %> inner %> outer %>")
      assert @parser.parse("<% outer <%% inner <%% atomic %%> inner %%> outer %>")
    end
  end
end
